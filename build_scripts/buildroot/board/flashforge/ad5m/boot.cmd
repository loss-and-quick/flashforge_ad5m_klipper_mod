# FlashForge AD5M Boot Script for Linux 6.6
#
# The kernel and the device tree are read from the ext4 root filesystem first:
# the FAT boot partition is small and prone to inconsistent cluster chains, so
# writing a large image to it from the running system can leave a file the
# bootloader reads back as garbage. The FAT partition remains a fallback and
# still holds the boot logo and the vendor bootloader copies.
setenv bootargs "earlycon=uart8250,mmio32,0x02500c00 console=ttyS3,115200 root=/dev/mmcblk0p6 rootwait rw init=/sbin/init panic=10 clk_ignore_unused"

if test -z "${kernel_addr_r}"; then setenv kernel_addr_r 0x42000000; fi
if test -z "${fdt_addr_r}"; then setenv fdt_addr_r 0x43000000; fi

echo "Loading Linux 6.6 kernel..."
if ext4load mmc 0:6 ${kernel_addr_r} /boot/zImage; then
    echo "Kernel loaded from the ext4 root filesystem."
else
    echo "ext4 copy unavailable, falling back to the FAT boot partition."
    if ! load mmc 0:1 ${kernel_addr_r} zImage; then
        echo "ERROR: failed to load a kernel image!"
        exit
    fi
fi

echo "Loading Device Tree..."
fdt_loaded=0
for fdt in /boot/sunxi.dtb /boot/sun8i-t113s4-flashforge-ad5m.dtb /boot/sun8i-t113s3-flashforge-ad5m.dtb; do
    if test "${fdt_loaded}" = "0"; then
        if ext4load mmc 0:6 ${fdt_addr_r} ${fdt}; then
            fdt_loaded=1
        fi
    fi
done
if test "${fdt_loaded}" = "0"; then
    for fdt in sunxi.dtb sun8i-t113s4-flashforge-ad5m.dtb sun8i-t113s3-flashforge-ad5m.dtb; do
        if test "${fdt_loaded}" = "0"; then
            if load mmc 0:1 ${fdt_addr_r} ${fdt}; then
                fdt_loaded=1
            fi
        fi
    done
fi

if test "${fdt_loaded}" = "1"; then
    echo "Booting Linux 6.6..."
    bootz ${kernel_addr_r} - ${fdt_addr_r}
else
    echo "ERROR: failed to load a device tree!"
    exit
fi
