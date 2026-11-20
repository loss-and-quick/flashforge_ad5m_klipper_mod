# FlashForge AD5M Boot Script for Linux 6.6
setenv bootargs "earlycon=uart8250,mmio32,0x02500c00 console=ttyS3,115200 root=/dev/mmcblk0p6 rootwait rw init=/sbin/init panic=10 clk_ignore_unused"

if test -z "${kernel_addr_r}"; then setenv kernel_addr_r 0x42000000; fi
if test -z "${fdt_addr_r}"; then setenv fdt_addr_r 0x43000000; fi
if test -z "${devtype}"; then setenv devtype mmc; fi
if test -z "${devnum}"; then setenv devnum 0; fi
if test -z "${distro_bootpart}"; then setenv distro_bootpart 1; fi

echo "Loading Linux 6.6 kernel from ${devtype} ${devnum}:${distro_bootpart}..."
if load ${devtype} ${devnum}:${distro_bootpart} ${kernel_addr_r} zImage; then
    echo "Kernel loaded successfully."
else
    echo "ERROR: Failed to load zImage!"
    exit
fi

echo "Loading Device Tree from ${devtype} ${devnum}:${distro_bootpart}..."
fdt_loaded=0
if test -e ${devtype} ${devnum}:${distro_bootpart} sunxi.dtb; then
    if load ${devtype} ${devnum}:${distro_bootpart} ${fdt_addr_r} sunxi.dtb; then
        fdt_loaded=1
    fi
elif test -n "${fdtfile}" && test -e ${devtype} ${devnum}:${distro_bootpart} ${fdtfile}; then
    if load ${devtype} ${devnum}:${distro_bootpart} ${fdt_addr_r} ${fdtfile}; then
        fdt_loaded=1
    fi
elif test -e ${devtype} ${devnum}:${distro_bootpart} sun8i-t113s4-flashforge-ad5m.dtb; then
    if load ${devtype} ${devnum}:${distro_bootpart} ${fdt_addr_r} sun8i-t113s4-flashforge-ad5m.dtb; then
        fdt_loaded=1
    fi
elif test -e ${devtype} ${devnum}:${distro_bootpart} sun8i-t113s3-flashforge-ad5m.dtb; then
    if load ${devtype} ${devnum}:${distro_bootpart} ${fdt_addr_r} sun8i-t113s3-flashforge-ad5m.dtb; then
        fdt_loaded=1
    fi
fi

if test "${fdt_loaded}" = "1"; then
    echo "Device tree loaded successfully. Booting Linux 6.6..."
    bootz ${kernel_addr_r} - ${fdt_addr_r}
else
    echo "ERROR: Failed to load Device Tree!"
    exit
fi
