# Building Klipper Mod from Source

This document describes how to compile the standalone FlashForge Adventurer 5M (AD5M / AD5M Pro) firmware, including the Linux 6.6 LTS kernel, U-Boot 2024.10 bootloader with native SPL, and Buildroot userspace variants.

---

## 1. Prerequisites & Environment

### Host System Requirements
- Linux distribution (Ubuntu 22.04+, Debian 12+, Arch Linux, NixOS, Fedora)
- Minimum 16 GB free disk space
- Standard Buildroot dependencies:
  ```bash
  # Debian / Ubuntu:
  sudo apt install -y build-essential gcc g++ make binutils patch bzip2 perl \
      tar cpio unzip rsync file bc git wget libncurses-dev libssl-dev python3 \
      python3-pip bison flex xz-utils
  ```

### Cloning with Submodules
Ensure submodules (especially Buildroot) are initialized:
```bash
git clone https://github.com/xblax/flashforge_ad5m_klipper_mod.git
cd flashforge_ad5m_klipper_mod
git submodule update --init --recursive
```

---

## 2. Build Pipeline Overview

The build process is divided into two phases:
1. **SDK Build**: Compiles a unified cross-toolchain (`arm-buildroot-linux-gnueabihf-gcc 14`, `glibc`, Linux 6.6 LTS kernel headers) in `build_output/buildroot/sdk/host/`.
2. **Variant Build**: Uses the precompiled SDK toolchain to build the Linux 6.6 LTS kernel, U-Boot, device trees, out-of-tree kernel modules (`rtl8821cu`), and the root filesystem.

---

## 3. Step-by-Step Build Commands

### Step 1: Build the SDK Toolchain
```bash
make sdk
# Or using the build script directly:
build_scripts/build.sh prepare_sdk
build_scripts/build.sh build_sdk
```
*(This step takes ~10–15 minutes on a modern multi-core processor and only needs to be run once).*

### Step 2: Build a Firmware Variant
Choose one of the available firmware variants:
- **`lite`** — Headless variant with Fluidd, Mainsail, Moonraker, and Klipper.
- **`klipperscreen`** — Full [KlipperScreen](KLIPPER_SCREEN.md) GUI on the 4.3" touchscreen.
- **`guppyscreen`** — Lightweight [GuppyScreen](GUPPY_SCREEN.md) UI.

```bash
# Build the lite variant:
make lite

# Or build KlipperScreen variant:
make klipperscreen

# Or build GuppyScreen variant:
make guppyscreen
```

### Clean / Rebuild
```bash
# Clean a variant:
build_scripts/build.sh clean_variant lite

# Rebuild only the Linux kernel:
make -C build_output/buildroot/variant-lite linux-rebuild

# Rebuild only U-Boot:
make -C build_output/buildroot/variant-lite uboot-rebuild
```

---

## 4. Build Configuration Options

You can customize the build using environment variables:

| Variable | Default | Description |
| :--- | :--- | :--- |
| `EMMC_OVERCLOCK` | `1` | Enable eMMC High-Speed DDR52 / HS200 mode up to 150 MHz (`1` = enabled, `0` = standard 52 MHz). |
| `MCU` | `stm32f103` | Target MCU architecture for Klipper MCU firmware (`stm32f103`, `gd32f303`). |
| `WITH_PLUGINS` | *(none)* | Space-separated list of optional plugins to include in the build. |

**Example:** Build with standard eMMC clock (52 MHz):
```bash
EMMC_OVERCLOCK=0 make lite
```

---

## 5. Output Artifacts

After a successful build, output files are located in `build_output/packages/` and `build_output/buildroot/variant-<name>/images/`:

- `build_output/packages/Adventurer5M-KlipperMod-<variant>-<version>.tgz` — USB installer archive for direct flashing via stock updater.
- `build_output/buildroot/variant-<variant>/images/ad5m-system.img` — Raw MBR disk image (containing SPL, U-Boot, boot, and rootfs partitions).
- `build_output/buildroot/variant-<variant>/images/u-boot-sunxi-with-spl.bin` — Standalone U-Boot binary with native SPL.
- `build_output/buildroot/variant-<variant>/images/zImage` — Mainline Linux 6.6 LTS compressed kernel.
- `build_output/buildroot/variant-<variant>/images/*.dtb` — Compiled device tree blobs for T113-S3 and T113-S4.
