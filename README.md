[![Mainsail](docs/images/mainsail_01_thumb.jpg)](docs/images/mainsail_01.jpg)
[![Fluidd](docs/images/fluidd_01_thumb.png)](docs/images/fluidd_01.png)
[![NoScreen](docs/images/no_screen_01_thumb.jpg)](docs/images/no_screen_01.jpg)
[![KlipperScreen](docs/images/klipper_screen_01_thumb.jpg)](docs/images/klipper_screen_01.jpg)

# Standalone Klipper Mod for FlashForge Adventurer 5M (Pro)

An open-source, **fully standalone** operating system for the FlashForge Adventurer 5M and Adventurer 5M Pro 3D printers. 

This firmware transitions the printer away from vendor-restricted environments and legacy chroot setups into a clean, modern Linux system powered by **mainline Linux 6.6 LTS**, **mainline U-Boot 2024.10 with native SPL**, and **Buildroot**, unlocking standard upstream Klipper, Moonraker, Mainsail, Fluidd, and KlipperScreen.

> [!CAUTION]
> *Installing custom firmware carries risks to your warranty and printer hardware. Proceed at your own risk.*

---

## Key Highlights & Architecture

- **Mainline Linux 6.6 LTS Kernel**: Upstream kernel with clean, dedicated device trees (`sun8i-t113-flashforge-ad5m.dtsi`, `sun8i-t113s3-flashforge-ad5m.dts`, `sun8i-t113s4-flashforge-ad5m.dts`).
- **Mainline U-Boot 2024.10 with Native SPL**: Direct hardware initialization without proprietary vendor bootloaders.
- **Dual SoC Support (T113-S3 & T113-S4)**: Automatic detection of Allwinner T113-S3 (128 MB DDR3) and T113-S4 (256 MB DDR3) at boot time via SID eFuse (`0x7200`), unlocking the full 256 MB DRAM on newer mainboard revisions.
- **eMMC Overclocking Option**: High-Speed DDR52 / HS200 mode up to 150 MHz delivering up to ~60 MB/s storage throughput (vs 12.5 MB/s stock). Configurable at build time via `EMMC_OVERCLOCK=1`.
- **Zero Binary Blobs**: All drivers (including Realtek RTL8821CU Wi-Fi, crypto engines, uinput) are built from open-source code.
- **Fully Integrated Hardware**:
  - **4.3" 800×480 LVDS Display**: Driven via the Allwinner T113 combo D-PHY in LVDS mode (`sun4i-drm`).
  - **Resistive Touchscreen**: 4-wire controller (`rtp@2009c00`, `allwinner,sun8i-ts`) driven by mainline `sun4i-ts` with calibrated tslib matrix.
  - **Networking**: 100M Ethernet (DWMAC + IP101GR PHY) and 802.11ac Wi-Fi (`rtl8821cu` via internal USB hub) managed by `iwd`.
  - **Serial MCUs**: Extruder MCU on UART1 (`PG6`/`PG7` @ 230,400) and Mainboard MCU on UART5 (`PG4`/`PG5` @ 230,400).
  - **Backlight & Buzzer**: PWM channel 7 (`PD22`) for display brightness, PWM channel 3 (`PB0`) for tone/melody generation.
- **Dual Delivery Strategy**:
  - **USB Flash Installer Package** (`Adventurer5M-KlipperMod*.tgz`): Flashes the standalone kernel and root filesystem directly to eMMC partitions p1 and p6 in-place via the stock update mechanism (no opening the printer or soldering required).
  - **Raw Disk Image** (`ad5m-system.img`): MBR disk image containing SPL, U-Boot, boot, and rootfs partitions for direct flashing or recovery.

---

## Included Software & Features

- **[Klipper](https://www.klipper3d.org/)** 0.13 — Custom configurations, improved default macros, and load-cell probing support.
- **[Moonraker](https://github.com/Arksine/moonraker)** API server (port `7125`).
- **Web Interfaces**: [Fluidd](https://docs.fluidd.xyz/) and [Mainsail](https://docs.mainsail.xyz/) on port `4000`.
- **Display Variants**:
  - **`lite`** — Headless / Web-only variant for maximum free RAM.
  - **`klipperscreen`** — Full [KlipperScreen](docs/KLIPPER_SCREEN.md) touch interface on the 4.3" LCD.
  - **`guppyscreen`** — Lightweight [GuppyScreen](docs/GUPPY_SCREEN.md) touch UI.
- **Camera Streaming**: High-performance streaming via [ustreamer](https://github.com/pikvm/ustreamer) on port `8080`.
- **[Moonraker-Timelapse](https://github.com/mainsail-crew/moonraker-timelapse)** for automated print videos.
- **SSH Root Access**: Port `22` (User: `root`, Password: `klipper`).
- **Audio & Melodies**: Buzzer playback via `python-ff-ad5m-audio`.
- **Automatic USB Drive Mounting** for print jobs and config overlays.

---

## Quick Start & Documentation

1. **[Installation Guide](docs/INSTALL.md)**: Flashing via USB drive or raw disk image.
2. **[Building from Source](docs/BUILDING.md)**: How to compile the SDK, kernel, U-Boot, and system variants.
3. **[Linux System Architecture](docs/LINUX.md)**: In-depth technical breakdown of kernel, bootloader, storage, and drivers.
4. **[LCD & Touchscreen](docs/LCD.md)**: Display interface, touchscreen calibration, and backlight control.
5. **[Wi-Fi Configuration](docs/WIFI.md)**: Setting up wireless networking with `iwd`.
6. **[Slicing Guide](docs/SLICING.md)**: Slicer profiles and start/end G-Code setup.
7. **[Buzzer & Audio](docs/BUZZER.md)**: Playing sounds and alerts.
8. **[Camera Setup](docs/CAMERA.md)**: Connecting and configuring USB webcams.
9. **[Uninstallation](docs/UNINSTALL.md)**: Reverting back to stock firmware.
