#!/bin/sh
set -ex

# workdir contains our update files
cd "$(dirname "$0")"
WORK_DIR="$(pwd)"
MACHINE=$1
PID=$2

# error handling
error_handler() {
  xzcat $WORK_DIR/img/uninstall_fail_error.img.xz > /dev/fb0
  sync
  # always exit without error, to prevent immediate boot of flashforge software
  exit 0
}
trap '[ $? -eq 0 ] && exit 0 || error_handler' EXIT

do_setup()
{
    MOD_INIT_FILE="/etc/init.d/S00klipper_mod"
    MOD_INIT_LOG_PREFIX="/root/mod_init"
    MOD_DIR="/data/.klipper_mod"

    # Restore stock rootfs if backup exists
    if [ -f /data/stock_rootfs.img.gz ] && [ -b /dev/mmcblk0p6 ]; then
        echo "Restoring stock rootfs to /dev/mmcblk0p6..."
        zcat /data/stock_rootfs.img.gz | dd of=/dev/mmcblk0p6 bs=64k conv=fsync
        sync
        rm -f /data/stock_rootfs.img.gz
        echo "Stock rootfs restored."
    fi

    # Restore stock boot files if backed up on /dev/mmcblk0p1
    if [ -b /dev/mmcblk0p1 ]; then
        mkdir -p /tmp/boot_part
        if mount /dev/mmcblk0p1 /tmp/boot_part 2>/dev/null; then
            if [ -f /tmp/boot_part/stock_spl.bak ]; then
                echo "Restoring stock U-Boot SPL..."
                dd if=/tmp/boot_part/stock_spl.bak of=/dev/mmcblk0 bs=1k seek=8 conv=notrunc,fsync
                rm -f /tmp/boot_part/stock_spl.bak
            fi
            if [ -f /tmp/boot_part/uimage.stock ]; then
                cp -f /tmp/boot_part/uimage.stock /tmp/boot_part/uimage
                rm -f /tmp/boot_part/uimage.stock
            fi
            if [ -f /tmp/boot_part/sunxi.dtb.stock ]; then
                cp -f /tmp/boot_part/sunxi.dtb.stock /tmp/boot_part/sunxi.dtb
                rm -f /tmp/boot_part/sunxi.dtb.stock
            fi
            rm -f /tmp/boot_part/boot.scr /tmp/boot_part/zimage /tmp/boot_part/sun8i-t113*.dtb 2>/dev/null || true
            sync
            umount /tmp/boot_part 2>/dev/null || true
        fi
    fi

    # remove everything
    rm -f "$MOD_INIT_FILE"
    rm -f "$MOD_INIT_LOG_PREFIX"*
    rm -rf "$MOD_DIR"

    # update end image
    xzcat $WORK_DIR/img/uninstall_ok.img.xz > /dev/fb0
}

# write log (if mount point is found)
if grep "^/dev/sd[ab12]* /mnt " /proc/mounts; then
  do_setup &> /mnt/klipper_mod_uninstall.log
  sync
else
  do_setup
fi

exit 0
