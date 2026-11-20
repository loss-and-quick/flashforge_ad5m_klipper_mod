#!/usr/bin/env bash
set -e

BOARD_DIR="$(dirname "$0")"
BINARIES_DIR="$1"
HOST_DIR="${HOST_DIR:-$(dirname "$BINARIES_DIR")/host}"
TARGET_DIR="${TARGET_DIR:-$(dirname "$BINARIES_DIR")/target}"
MKIMAGE_BIN="${HOST_DIR}/bin/mkimage"
[ -x "${MKIMAGE_BIN}" ] || MKIMAGE_BIN="mkimage"
GENIMAGE_CFG="${BOARD_DIR}/genimage.cfg"
GENIMAGE_TMP="${BUILD_DIR:-$(dirname "$BINARIES_DIR")/build}/genimage.tmp"

# Generate or update uImage from zImage
if [ -f "${BINARIES_DIR}/zImage" ]; then
    if [ ! -f "${BINARIES_DIR}/uImage" ] || [ "${BINARIES_DIR}/zImage" -nt "${BINARIES_DIR}/uImage" ]; then
        "${MKIMAGE_BIN}" -A arm -O linux -T kernel -C none \
            -a 0x40008000 -e 0x40008000 -n "Linux-6.6" \
            -d "${BINARIES_DIR}/zImage" "${BINARIES_DIR}/uImage"
    fi
fi

# Keep the default device tree used by generic bootloader configs (S4) in
# sync with the freshly built one: copying only when it is missing left a
# stale sunxi.dtb in the image.
if [ -f "${BINARIES_DIR}/sun8i-t113s4-flashforge-ad5m.dtb" ]; then
    cp -f "${BINARIES_DIR}/sun8i-t113s4-flashforge-ad5m.dtb" "${BINARIES_DIR}/sunxi.dtb"
fi

# Adjust CPU frequency if overclock is disabled (defaults to 1.2 GHz in DTS)
if grep -qE "BR2_PACKAGE_AD5M_CPU_OVERCLOCK=n|# BR2_PACKAGE_AD5M_CPU_OVERCLOCK is not set" "${BUILD_DIR}/../.config" 2>/dev/null; then
    for dtb in "${BINARIES_DIR}"/*.dtb; do
        if [ -f "$dtb" ] && [ -x "${HOST_DIR}/bin/fdtput" ]; then
            "${HOST_DIR}/bin/fdtput" -t i "$dtb" "/soc/clock-controller@2001000" "assigned-clock-rates" 100000000 1008000000 2>/dev/null || true
        fi
    done
fi

# Adjust eMMC frequency if overclock is disabled (mmc0 @ 0x4020000)
if grep -qE "BR2_PACKAGE_AD5M_EMMC_OVERCLOCK=n|# BR2_PACKAGE_AD5M_EMMC_OVERCLOCK is not set" "${BUILD_DIR}/../.config" 2>/dev/null; then
    for dtb in "${BINARIES_DIR}"/*.dtb; do
        if [ -f "$dtb" ] && [ -x "${HOST_DIR}/bin/fdtput" ]; then
            "${HOST_DIR}/bin/fdtput" -t i "$dtb" "/soc/mmc@4020000" "max-frequency" 52000000 2>/dev/null || true
        fi
    done
fi

# Generate boot.scr from boot.cmd
if [ -f "${BOARD_DIR}/boot.cmd" ]; then
    "${MKIMAGE_BIN}" -A arm -O linux -T script -C none \
        -d "${BOARD_DIR}/boot.cmd" "${BINARIES_DIR}/boot.scr"
fi

# Run genimage to produce full eMMC/SD image
if [ -f "${GENIMAGE_CFG}" ]; then
    rm -rf "${GENIMAGE_TMP}"
    GENIMAGE_BIN="${HOST_DIR}/bin/genimage"
    [ -x "${GENIMAGE_BIN}" ] || GENIMAGE_BIN="genimage"
    "${GENIMAGE_BIN}" \
        --rootpath "${TARGET_DIR}" \
        --tmppath "${GENIMAGE_TMP}" \
        --inputpath "${BINARIES_DIR}" \
        --outputpath "${BINARIES_DIR}" \
        --config "${GENIMAGE_CFG}"
fi

exit 0
