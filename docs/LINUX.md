# Linux Environment

The FlashForge Adventurer 5M (AD5M / AD5M Pro) firmware is a modern standalone embedded Linux system built from source with [Buildroot](https://buildroot.org/).

Unlike the original vendor firmware or legacy mod versions that ran inside a chroot jail on an old Linux 5.4.61 kernel with binary blobs, this system is **100% standalone and open source**:
- **Mainline Linux Kernel**: Linux 6.6 LTS with upstream device trees and native drivers.
- **Mainline U-Boot**: U-Boot 2024.10 with native SPL (`u-boot-sunxi-with-spl.bin`).
- **No Vendor Binary Blobs**: All kernel modules (including Wi-Fi `8821cu`, crypto, uinput) are compiled from source.
- **Full SoC Support**: Works seamlessly on both Allwinner T113-S3 (128MB DDR3) and T113-S4 (256MB DDR3) with automatic chip ID detection at boot.

Connect via SSH to explore the system:
- **Port**: 22
- **User**: `root`
- **Password**: `klipper`

---

## Hardware Architecture & Drivers

### SoC & Memory Auto-Detection
The motherboard uses an Allwinner T113 dual-core Cortex-A7 processor. Depending on hardware revision, the board is fitted with:
- **Allwinner T113-S3**: 128 MB co-packaged DDR3 RAM.
- **Allwinner T113-S4**: 256 MB co-packaged DDR3 RAM.

U-Boot SPL reads the Allwinner SID eFuse chip ID (`0x7200` = T113-S4) during early initialization. For S4 chips, address conflict (AC) remapping is automatically disabled and all 256 MB DRAM is mapped. The boot script passes the appropriate device tree:
- `sun8i-t113s3-flashforge-ad5m.dtb` (128 MB memory node)
- `sun8i-t113s4-flashforge-ad5m.dtb` (256 MB memory node)

### Storage & eMMC Overclocking
The onboard storage is an 8 GB eMMC connected via `mmc2` with a 4-bit data bus (`/dev/mmcblk0`).
- **Stock speed**: 25 MHz (~12.5 MB/s).
- **Overclocked speed**: High-Speed DDR52 / HS200 mode up to 150 MHz (delivering up to ~60 MB/s read/write throughput). Overclocking is switchable at build time via `EMMC_OVERCLOCK=1` or `BR2_PACKAGE_AD5M_EMMC_OVERCLOCK=y`.

### Display & Touchscreen
- **Display**: 4.3" 800x480 single-link LVDS display (VESA-24 format) driven by the T113 Display Engine (DE2) via the combo D-PHY in LVDS mode (`sun4i-drm` / `panel-simple`).
- **Touchscreen**: On-die 4-wire resistive touchscreen controller (`rtp@2009c00`, `allwinner,sun8i-ts`) handled by the `sun4i-ts` driver. Calibrated with standard tslib matrix: `15066 -97 -4089040 -221 -11814 40462876 65536 800 480`.
- **Backlight**: Controlled via PWM channel 7 on pin `PD22`.

### Networking
- **Ethernet**: Allwinner DWMAC 10/100 Ethernet controller (`4500000.eth`) paired with an IP101GR PHY at MDIO address 1.
- **Wi-Fi**: Realtek RTL8821CU 802.11ac Wi-Fi + Bluetooth 4.2 module connected via an internal Genesys Logic USB 2.0 hub (`0bda:c811`). Driver `rtl8821cu` is built out-of-tree from source. Managed by `iwd` (iNet wireless daemon).

### Serial Communications & MCUs
- **Extruder MCU** (`/dev/ttyS1`): Connected to UART1 on pins `PG6` (TX) / `PG7` (RX) running at 230,400 baud.
- **Mainboard MCU** (`/dev/ttyS5`): Connected to UART5 on pins `PG4` (TX) / `PG5` (RX) running at 230,400 baud.
- **Debug Serial Console** (`/dev/ttyS3`): Accessible via test points / headers using UART3 on pins `PG8` (TX) / `PG9` (RX) at 115,200 baud.

### Audio / Buzzer
- **Piezo Buzzer**: Driven by PWM channel 3 on pin `PB0`, capable of playing tones and MIDI melodies via `python-ff-ad5m-audio`.

---

## Partition Layout

The eMMC storage is partitioned as follows:

| Partition | Device | Filesystem | Mount Point | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| MBR / Raw | `/dev/mmcblk0` | Raw sectors | — | Sector 16: U-Boot SPL (`u-boot-sunxi-with-spl.bin`) |
| Partition 1 | `/dev/mmcblk0p1` | VFAT | `/boot` | `boot.scr`, `zImage`, `sun8i-t113s*.dtb` |
| Partition 6 | `/dev/mmcblk0p6` | EXT4 | `/` | Root filesystem (system binaries, libraries, services) |
| Partition 7 | `/dev/mmcblk0p7` | EXT4 | `/root/printer_data` | Persistent user data (Klipper configs, logs, G-Codes) |

---

## Important File Paths

- `/opt/klipper` — Klipper host software
- `/opt/moonraker` — Moonraker API server
- `/root/printer_data/config` — Printer configuration files (`printer.cfg`, macros)
- `/root/printer_data/gcodes` — Uploaded G-Code files
- `/root/printer_data/logs` — Klipper and Moonraker log files
- `/var/lib/iwd` — Wi-Fi network profile configurations
- `/etc/init.d/` — SysV init service scripts (`S60klipper`, `S65moonraker`, etc.)
