# Installation Guide

The modern standalone Klipper Mod can be installed on the FlashForge Adventurer 5M and Adventurer 5M Pro using either the standard USB drive update mechanism (no opening the printer or soldering required) or by flashing a raw disk image.

> [!CAUTION]
> *Installing custom firmware carries inherent risks. Proceed at your own risk.*

---

## Method 1: USB Flash Drive Update (Recommended)

This method flashes the standalone Linux 6.6 LTS kernel, U-Boot, and root filesystem directly into the printer's onboard eMMC storage using the built-in firmware updater.

### Prerequisites
- A USB flash drive formatted as **FAT32**.
- A printer running stock firmware version **2.4.5** or newer.

### Installation Steps
1. Download the latest release archive (`Adventurer5M-KlipperMod-<variant>-<version>.tgz`) from the [Releases](https://github.com/xblax/flashforge_ad5m_klipper_mod/releases) page.
   - For **AD5M Pro**, rename the archive to `Adventurer5MPro-<variant>-<version>.tgz` so the printer recognizes it.
2. Copy the `.tgz` archive to the root directory of your USB flash drive.
3. Power off the printer.
4. Insert the USB drive into the printer's front USB port.
5. Power on the printer. The printer will detect the update package and begin the flashing process.
6. The installer will:
   - Verify package integrity (MD5 checksums).
   - Write the standalone kernel (`zImage`), device tree blobs, and `boot.scr` to `/dev/mmcblk0p1` (boot partition).
   - Flash the root filesystem image to `/dev/mmcblk0p6` (system partition).
   - Preserve existing user configs, Moonraker database, and G-Code files on `/dev/mmcblk0p7` (data partition).
7. When flashing is complete, the screen will indicate success (or the buzzer will chime). Unplug the USB drive and restart the printer.

### Custom File Pre-Configuration
You can pre-configure Wi-Fi, SSH keys, or network settings before first boot by creating a `klipper_mod/` folder on the root of the USB drive alongside the update archive:
- Example: `klipper_mod/var/lib/iwd/MyNetwork.psk` will be automatically installed to `/var/lib/iwd/MyNetwork.psk`.

### Installation Log File
A detailed log is written to `klipper_mod_install.log` on the USB drive during the installation. If anything goes wrong, inspect this file to diagnose the issue.

---

## Method 2: Raw Disk Image Flashing (`ad5m-system.img`)

For complete system recovery, developer testing, or flashing via an external eMMC programmer / FEL mode:
1. Locate the built or downloaded `ad5m-system.img`.
2. The image contains the full MBR partition layout:
   - `Sector 16`: `u-boot-sunxi-with-spl.bin` (native SPL + U-Boot).
   - `Partition 1` (VFAT): Boot partition containing kernel, DTBs, and boot script.
   - `Partition 2` (EXT4): Standalone root filesystem.
3. Flash the image directly to the eMMC block device:
   ```bash
   # When using an external SD/eMMC writer on Linux:
   sudo dd if=ad5m-system.img of=/dev/sdX bs=4M status=progress conv=fsync
   ```

---

## Initial Network Access

By default, the standalone system uses DHCP on both Ethernet and Wi-Fi.

1. **Ethernet**: Plug in an Ethernet cable connected to your local network. Check your router's DHCP client list for `ad5m-klipper` or scan your network for port 80/7125.
2. **Web Interface**: Open `http://<printer-ip>:4000` (or `http://<printer-ip>` depending on variant) in a web browser to access Fluidd or Mainsail.
3. **SSH Access**:
   ```bash
   ssh root@<printer-ip>
   # Default password: klipper
   ```

To configure Wi-Fi after booting, see [Wi-Fi Configuration](WIFI.md).
