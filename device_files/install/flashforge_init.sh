#!/bin/sh
set -ex
set -o pipefail 2>/dev/null || true

# workdir contains our update files
cd "$(dirname "$0")"
WORK_DIR="$(pwd)"
MACHINE=$1
PID=$2

# error handling
error_handler() {
  umount /tmp/boot_part 2>/dev/null || true
  if [ -e /dev/fb0 ] && [ -f "$WORK_DIR/img/install_fail_error.img.xz" ]; then
    xzcat "$WORK_DIR/img/install_fail_error.img.xz" > /dev/fb0 2>/dev/null || true
  fi
  sync
  # always exit without error, to prevent immediate boot of flashforge software
  exit 0
}
trap '[ $? -eq 0 ] && exit 0 || error_handler' EXIT

version_ge() {
    [ "$(printf '%s\n' "$2" "$1" | sort -V 2>/dev/null | head -n1)" = "$2" ]
}

do_setup()
{
    # safety check, only install on supported printer
    if ([ "$MACHINE" != "Adventurer5M" ] && [ "$MACHINE" != "Adventurer5MPro" ]) || \
       ([ "$PID" != "0023" ] && [ "$PID" != "0024" ]) || \
        [ "$(uname -m)" != "armv7l" ]
     then
        echo "Update file does not match machine type."
        [ -e /dev/fb0 ] && xzcat $WORK_DIR/img/install_fail_vers.img.xz > /dev/fb0 2>/dev/null || true
        exit 0
    fi

    # safety check, only install on supported versions (>= 2.4.5)
    FF_VERSION="$(cat /root/version 2>/dev/null || echo "0.0.0")"
    MIN_VERSION="2.4.5"
    if ! version_ge "$FF_VERSION" "$MIN_VERSION"; then
        echo "Printer software version $FF_VERSION not supported (minimum: $MIN_VERSION)."
        [ -e /dev/fb0 ] && xzcat $WORK_DIR/img/install_fail_vers.img.xz > /dev/fb0 2>/dev/null || true
        exit 0
    fi

    # check free space, we require 512MB before installation for safety reasons
    FREE_SPACE=$(df /data | tail -1 | tr -s ' ' | cut -d' ' -f4)
    MIN_SPACE="524228"
    if [ -n "$FREE_SPACE" ] && [ "$FREE_SPACE" -lt "$MIN_SPACE" ]; then
        echo "Not enough free space on data partition. 512MB required!";
        [ -e /dev/fb0 ] && xzcat $WORK_DIR/img/install_fail_mem.img.xz > /dev/fb0 2>/dev/null || true
        exit 0
    fi

    MOD_INIT_FILE="/etc/init.d/S00klipper_mod"
    MOD_INIT_FILE_OLD="/etc/init.d/S90klipper_mod"
    MOD_DIR="/data/.klipper_mod"
    CHROOT_DIR="${MOD_DIR}/chroot"

    # update start image
    [ -e /dev/fb0 ] && xzcat $WORK_DIR/img/install_start.img.xz > /dev/fb0 2>/dev/null || true
    # --------------------------------

    # calculate checksums to be printed in the log
    if ls /mnt/Adventurer5M* 1>/dev/null 2>&1; then
      md5sum /mnt/Adventurer5M* || true
    fi

    # Verify target partitions exist
    if [ ! -b /dev/mmcblk0p1 ] || [ ! -b /dev/mmcblk0p6 ]; then
        echo "ERROR: Target eMMC partitions (/dev/mmcblk0p1, /dev/mmcblk0p6) not found!"
        exit 1
    fi

    # uninstall previous mod init scripts (keep persistent data)
    rm -f $MOD_INIT_FILE
    rm -f $MOD_INIT_FILE_OLD

    if [ -f "$WORK_DIR/rootfs.ext4.xz" ]; then
        echo "Installing standalone Klipper Mod system..."
        md5sum "$WORK_DIR/rootfs.ext4.xz"

        # Migrate persistent settings, databases, and configs from legacy mod
        mkdir -p /data/printer_data/database /data/printer_data/gcodes /data/printer_data/logs /data/printer_data/config
        mkdir -p /data/system/iwd /data/system/ssh /data/system/dropbear

        LEGACY_STATIC="/data/.klipper_mod/static"
        if [ -d "$LEGACY_STATIC" ]; then
            echo "Migrating data from legacy mod..."
            [ -d "$LEGACY_STATIC/var/lib/iwd" ] && cp -an "$LEGACY_STATIC/var/lib/iwd/"* /data/system/iwd/ 2>/dev/null || true
            [ -d "$LEGACY_STATIC/root/.ssh" ] && cp -an "$LEGACY_STATIC/root/.ssh/"* /data/system/ssh/ 2>/dev/null || true
            [ -d "$LEGACY_STATIC/etc/dropbear" ] && cp -an "$LEGACY_STATIC/etc/dropbear/"* /data/system/dropbear/ 2>/dev/null || true
            [ -d "$LEGACY_STATIC/root/printer_data/database" ] && cp -an "$LEGACY_STATIC/root/printer_data/database/"* /data/printer_data/database/ 2>/dev/null || true
            [ -d "$LEGACY_STATIC/root/printer_data/gcodes" ] && cp -an "$LEGACY_STATIC/root/printer_data/gcodes/"* /data/printer_data/gcodes/ 2>/dev/null || true
            [ -d "$LEGACY_STATIC/root/printer_data/config" ] && cp -an "$LEGACY_STATIC/root/printer_data/config/"* /data/printer_data/config/ 2>/dev/null || true
        fi

        # Pre-configuration from USB drive (if user placed klipper_mod/ on USB)
        USB_PRECONF=""
        if [ -d "/mnt/klipper_mod" ]; then
            USB_PRECONF="/mnt/klipper_mod"
        elif [ -d "$WORK_DIR/klipper_mod" ]; then
            USB_PRECONF="$WORK_DIR/klipper_mod"
        fi
        if [ -n "$USB_PRECONF" ]; then
            echo "Applying pre-configurations from USB drive ($USB_PRECONF)..."
            [ -d "$USB_PRECONF/var/lib/iwd" ] && cp -an "$USB_PRECONF/var/lib/iwd/"* /data/system/iwd/ 2>/dev/null || true
            [ -d "$USB_PRECONF/root/.ssh" ] && cp -an "$USB_PRECONF/root/.ssh/"* /data/system/ssh/ 2>/dev/null || true
            [ -d "$USB_PRECONF/printer_data" ] && cp -an "$USB_PRECONF/printer_data/"* /data/printer_data/ 2>/dev/null || true
        fi

        # Create stock rootfs backup if not already present
        if [ ! -f /data/stock_rootfs.img.gz ]; then
            echo "Creating backup of stock rootfs to /data/stock_rootfs.img.gz..."
            gzip -1 -c /dev/mmcblk0p6 > /data/stock_rootfs.img.gz 2>/dev/null || true
            sync
        fi

        # Detect T113-S3 vs S4 via SID eFuse
        CHIP_ID=""
        if [ -f /sys/bus/nvmem/devices/sunxi-sid0/nvmem ]; then
            CHIP_ID=$(hexdump -n 2 -e '1/2 "%04x"' /sys/bus/nvmem/devices/sunxi-sid0/nvmem 2>/dev/null || true)
        fi
        if [ "$CHIP_ID" = "7200" ]; then
            echo "Detected Allwinner T113-S4 (256MB)"
            DTB_SRC="sun8i-t113s4-flashforge-ad5m.dtb"
        else
            echo "Detected Allwinner T113-S3 (128MB)"
            DTB_SRC="sun8i-t113s3-flashforge-ad5m.dtb"
        fi

        # Mount boot partition /dev/mmcblk0p1 and update kernel & DTB
        mkdir -p /tmp/boot_part
        mount /dev/mmcblk0p1 /tmp/boot_part

        # Backup stock files if not already saved
        if [ -f /tmp/boot_part/uimage ] && [ ! -f /tmp/boot_part/uimage.stock ]; then
            cp -f /tmp/boot_part/uimage /tmp/boot_part/uimage.stock
        fi
        if [ -f /tmp/boot_part/sunxi.dtb ] && [ ! -f /tmp/boot_part/sunxi.dtb.stock ]; then
            cp -f /tmp/boot_part/sunxi.dtb /tmp/boot_part/sunxi.dtb.stock
        fi

        # The stock FAT partition advertises more sectors in its boot sector
        # than the partition holds, so a kernel copied into it can come back
        # corrupted after a reboot. Store the kernel and device tree in the
        # root filesystem and only refresh the FAT copy when it survives a
        # read-back comparison.
        install_boot_file_verified() {
            src="$1"
            dst="$2"
            cp -f "$src" "$dst" 2>/dev/null || return 1
            sync
            cmp -s "$src" "$dst"
        }

        if [ -f "$WORK_DIR/zImage" ] && [ -d /boot ]; then
            cp -f "$WORK_DIR/zImage" /boot/zImage 2>/dev/null || true
        fi
        if [ -f "$WORK_DIR/$DTB_SRC" ] && [ -d /boot ]; then
            cp -f "$WORK_DIR/$DTB_SRC" /boot/sunxi.dtb 2>/dev/null || true
        fi
        if [ -f "$WORK_DIR/boot.scr" ] && [ -d /boot ]; then
            cp -f "$WORK_DIR/boot.scr" /boot/boot.scr 2>/dev/null || true
        fi

        if [ -f "$WORK_DIR/$DTB_SRC" ] && install_boot_file_verified "$WORK_DIR/$DTB_SRC" /tmp/boot_part/sunxi.dtb; then
            echo "Boot partition accepted the device tree."
        else
            echo "WARNING: the boot partition did not store the device tree reliably; the kernel is loaded from the root filesystem instead."
        fi
        if [ -f "$WORK_DIR/boot.scr" ] && install_boot_file_verified "$WORK_DIR/boot.scr" /tmp/boot_part/boot.scr; then
            echo "Boot partition accepted the boot script."
        fi
        # Install U-Boot 2024.10 if present with backup and verified readback
        if [ -f "$WORK_DIR/u-boot-sunxi-with-spl.bin" ]; then
            if [ ! -f /tmp/boot_part/stock_spl.bak ]; then
                echo "Backing up stock bootloader..."
                dd if=/dev/mmcblk0 of=/tmp/boot_part/stock_spl.bak bs=1k skip=8 count=512 2>/dev/null || true
            fi
            echo "Flashing U-Boot 2024.10 to eMMC..."
            dd if="$WORK_DIR/u-boot-sunxi-with-spl.bin" of=/dev/mmcblk0 bs=1k seek=8 conv=notrunc,fsync
            UBOOT_SIZE=$(wc -c < "$WORK_DIR/u-boot-sunxi-with-spl.bin")
            dd if=/dev/mmcblk0 bs=1 skip=8192 count="$UBOOT_SIZE" of=/tmp/uboot_rb.bin 2>/dev/null
            if cmp -s "$WORK_DIR/u-boot-sunxi-with-spl.bin" /tmp/uboot_rb.bin; then
                echo "U-Boot 2024.10 verified successfully on eMMC."
                rm -f /tmp/uboot_rb.bin
            else
                echo "ERROR: U-Boot verification failed! Restoring stock bootloader..."
                dd if=/tmp/boot_part/stock_spl.bak of=/dev/mmcblk0 bs=1k seek=8 conv=notrunc,fsync
                rm -f /tmp/uboot_rb.bin
                exit 1
            fi
        fi

        sync
        umount /tmp/boot_part

        # Flash rootfs partition
        echo "Flashing rootfs to /dev/mmcblk0p6..."
        xzcat "$WORK_DIR/rootfs.ext4.xz" | dd of=/dev/mmcblk0p6 bs=64k conv=fsync
        sync

        # Clean up legacy chroot files if present
        rm -rf "$CHROOT_DIR"
    elif [ -f "$WORK_DIR/chroot.tar.xz" ]; then
        echo "Installing legacy chroot environment..."
        md5sum "$WORK_DIR/chroot.tar.xz"

        # unpack chroot environment
        mkdir -p "$CHROOT_DIR"
        xz -dc "$WORK_DIR/chroot.tar.xz" | tar -xf - -C "$CHROOT_DIR"
        sync

        # do initial setup
        "$CHROOT_DIR/etc/init/S00klipper_mod" setup
        sync

        # install initfile
        cp "$CHROOT_DIR/etc/init/S00klipper_mod" /etc/init.d/
        sync
    fi

    # update end image
    # --------------------------------
    if [ -e /dev/fb0 ] && [ -f "$WORK_DIR/img/install_ok.img.xz" ]; then
        xzcat "$WORK_DIR/img/install_ok.img.xz" > /dev/fb0 2>/dev/null || true
    fi
}

# write log (if mount point is found)
if grep "^/dev/sd[ab12]* /mnt " /proc/mounts; then
  do_setup &> /mnt/klipper_mod_install.log
  sync
else
  do_setup
fi

exit 0
