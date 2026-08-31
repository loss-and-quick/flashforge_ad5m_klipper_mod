#!/bin/bash
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source "$SCRIPT_DIR/../env.sh"

BUILD_DIR_NAME="$(basename "$BASE_DIR")"

if [[ "$BUILD_DIR_NAME" =~ ^variant-(.+)$ ]]; then

    rest="${BASH_REMATCH[1]}"

    IFS='-' read -r -a parts <<< "$rest"

    BUILD_VARIANT="${parts[0]}"

    if [ "${#parts[@]}" -gt 1 ]; then
        BUILD_PLUGINS=( "${parts[@]:1}" )
    else
        BUILD_PLUGINS=()
    fi
fi

# Paths
TARGET_ROOT="$TARGET_DIR"

TSLIB_POINTERCAL="/mnt/orig_root/opt/tslib-1.12/etc/pointercal"
TSLIB_TSCONF="/mnt/orig_root/opt/tslib-1.12/etc/ts.conf"

install_tslib_requirements() {
    log_info "Initiating installation of TSLIB (Touchscreen Library) configuration files..."

    # Before creating new symbolic links, it's vital to ensure any old, stale, or
    # conflicting 'ts.conf' file is completely removed.
    log_info "  Checking for and removing any existing TSLIB configuration file at $TARGET_ROOT/etc/ts.conf to prevent conflicts."
    rm -f "$TARGET_ROOT/etc/ts.conf"

    # Create a symbolic link for 'pointercal'. This specific file contains the essential
    # calibration data for the touchscreen,
    log_info "  Creating symbolic link for TSLIB touchscreen calibration data: $TARGET_ROOT/etc/pointercal -> $TSLIB_POINTERCAL."
    ln -fs "$TSLIB_POINTERCAL" "$TARGET_ROOT/etc/pointercal"

    # Create a symbolic link for 'ts.conf'. This is the primary configuration file
    # for TSLIB, which dictates precisely how raw touchscreen events are processed
    # and interpreted by the system.
    log_info "  Creating symbolic link for TSLIB's main configuration file: $TARGET_ROOT/etc/ts.conf -> $TSLIB_TSCONF."
    ln -fs "$TSLIB_TSCONF" "$TARGET_ROOT/etc/ts.conf"

    log_info "TSLIB configuration setup completed successfully."
}

add_klipper_includes() {
    local printer_cfg_path="$TARGET_ROOT/root/printer_data/config/printer.cfg"
    local includes_to_add=()
    
    log_info "Collecting Klipper configuration files that need to be included..."
    
    for cfg_file in "$@"; do
        if [[ "$cfg_file" == *.cfg ]] && [[ "$(basename "$cfg_file")" != "printer.cfg" ]]; then
            includes_to_add+=("$(basename "$cfg_file")")
            log_info "  Found Klipper config to include: $(basename "$cfg_file")"
        fi
    done
    
    if [ ${#includes_to_add[@]} -eq 0 ]; then
        log_info "No additional Klipper configuration files to include."
        return 0
    fi
    
    if [ ! -f "$printer_cfg_path" ]; then
        log_warn "printer.cfg not found at $printer_cfg_path. Skipping include additions."
        return 0
    fi
    
    log_info "Adding include directives to printer.cfg..."
    
    local includes_text=""
    includes_text+="\n# Auto-generated includes for plugins and variants\n"
    for cfg_include in "${includes_to_add[@]}"; do
        includes_text+="[include $cfg_include]\n"
        log_info "  Will add include directive: [include $cfg_include]"
    done
    
    if grep -q "^\[include " "$printer_cfg_path" 2>/dev/null; then
        local last_include_line
        last_include_line=$(grep -n "^\[include " "$printer_cfg_path" | tail -1 | cut -d: -f1)
        if [ -n "$last_include_line" ]; then
            sed -i "${last_include_line}a\\${includes_text}" "$printer_cfg_path" 2>/dev/null || {
                log_warn "Failed to add includes using sed. Trying alternative method."
                echo -e "$includes_text" >> "$printer_cfg_path"
            }
        else
            echo -e "$includes_text" >> "$printer_cfg_path"
        fi
    else
        local temp_file
        if temp_file=$(mktemp 2>/dev/null); then
            {
                echo -e "# Auto-generated includes for plugins and variants"
                for cfg_include in "${includes_to_add[@]}"; do
                    echo "[include $cfg_include]"
                done
                echo ""
                cat "$printer_cfg_path"
            } > "$temp_file" && mv "$temp_file" "$printer_cfg_path"
        else
            echo -e "$includes_text" >> "$printer_cfg_path"
        fi
    fi
    
    log_info "Successfully updated printer.cfg with ${#includes_to_add[@]} include directive(s)."
}

log_info "Deactivating 'S35iptables' initscript (if exists)."
chmod -x "$TARGET_ROOT/etc/init.d/S35iptables" || true

log_info "Cleaning up old build artifacts."
rm -rf "$TARGET_ROOT/root/printer_data/"

log_info "Recording the current UTC build time into fake-hwclock"
date -u '+%Y-%m-%d %H:%M:%S' > "$TARGET_ROOT/etc/fake-hwclock.data"

pushd "$GIT_ROOT" > /dev/null
KLIPPER_MOD_VERSION=$(git describe --tags --always --abbrev=7)
popd > /dev/null

cat << EOF > "$TARGET_ROOT/etc/os-release"
NAME=Buildroot-AD5M
VERSION=-$KLIPPER_MOD_VERSION
ID=buildroot
VERSION_ID=$KLIPPER_MOD_VERSION
PRETTY_NAME="Klipper Mod $KLIPPER_MOD_VERSION"
EOF

log_info "Installing custom Klipper Python extensions into /opt/klipper/klippy/extras/."
cp "$GIT_ROOT/build_scripts/components/klipper_extensions/"* "$TARGET_ROOT/opt/klipper/klippy/extras/" || true

log_info "Installing custom Moonraker Python extensions into /opt/moonraker/moonraker/components/."
cp "$GIT_ROOT/build_scripts/components/moonraker_extensions/"* "$TARGET_ROOT/opt/moonraker/moonraker/components/" || true

log_info "Setting Moonraker API communication port to 7125 within Mainsail's configuration (/opt/mainsail/config.json). This ensures Mainsail can properly connect to Moonraker."
sed -i 's\"port": null\"port": 7125\g' "$TARGET_ROOT/opt/mainsail/config.json"

log_info "Disabling the Mainsail service by default. Mainsail will not start automatically on boot."
chmod -x "$TARGET_ROOT/etc/init.d/S70mainsail"
chmod +x "$TARGET_ROOT/etc/init.d/S70fluidd"
log_info "Mainsail service successfully disabled by default."

log_info "Initiating the copying process for essential printer configuration files."

mkdir -p "$TARGET_ROOT/root/printer_data/config"

log_info "  Copying all printer-specific configuration files from $GIT_ROOT/printer_configs to their final destination: /root/printer_data/config/."
cp -r "$GIT_ROOT/printer_configs/common/"* "$TARGET_ROOT/root/printer_data/config"

COPIED_CFG_FILES=()

if [ -n "$BUILD_VARIANT" ] && [ -d "$GIT_ROOT/printer_configs/variant-$BUILD_VARIANT" ]; then
    log_info "Processing variant-specific files for: $BUILD_VARIANT"
    for file in "$GIT_ROOT/printer_configs/variant-$BUILD_VARIANT"/*; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            log_info "  Copying variant file: $filename"
            cp "$file" "$TARGET_ROOT/root/printer_data/config/"
            if [[ "$filename" == *.cfg ]] && [[ "$filename" != "printer.cfg" ]]; then
                COPIED_CFG_FILES+=("$filename")
            fi
        fi
    done
fi

for plugin in "${BUILD_PLUGINS[@]}"; do
    plugin_config_dir="$GIT_ROOT/printer_configs/plugin-$plugin"
    if [ -d "$plugin_config_dir" ]; then
        log_info "Processing plugin-specific files for: $plugin"
        for file in "$plugin_config_dir"/*; do
            if [ -f "$file" ]; then
                filename=$(basename "$file")
                log_info "  Copying plugin file: $filename"
                cp "$file" "$TARGET_ROOT/root/printer_data/config/"
                if [[ "$filename" == *.cfg ]] && [[ "$filename" != "printer.cfg" ]]; then
                    COPIED_CFG_FILES+=("$filename")
                fi
            fi
        done
    else
        log_warn "Plugin configuration directory not found: $plugin_config_dir"
    fi
done

if [ ${#COPIED_CFG_FILES[@]} -gt 0 ]; then
    add_klipper_includes "${COPIED_CFG_FILES[@]}"
fi

log_info "Printer configurations successfully copied and staged for deployment."

log_info "Verifying and correcting D-Bus user and group entries in /etc/group, /etc/passwd, and /etc/shadow. This ensures D-Bus, a critical system message bus, operates securely."

# Checks if the 'dbus' group exists in /etc/group. If not, it adds the entry.
if ! grep -q dbus "$TARGET_ROOT/etc/group"; then
    log_warn "  'dbus' group not found in /etc/group. Adding entry for proper D-Bus functionality."
    echo "dbus:x:101:dbus" >> "$TARGET_ROOT/etc/group"
fi

# Checks if the 'dbus' user exists in /etc/passwd. If not, it adds the entry.
if ! grep -q dbus "$TARGET_ROOT/etc/passwd"; then
    log_warn "  'dbus' user not found in /etc/passwd. Adding entry for D-Bus messagebus user."
    echo "dbus:x:100:101:DBus messagebus user:/run/dbus:/bin/false" >> "$TARGET_ROOT/etc/passwd"
fi

# Checks if the 'dbus' user's shadow entry exists in /etc/shadow. If not, it adds a placeholder.
if ! grep -q dbus "$TARGET_ROOT/etc/shadow"; then
    log_warn "  'dbus' entry not found in /etc/shadow. Adding a placeholder entry for security consistency."
    echo "dbus:*:::::::" >> "$TARGET_ROOT/etc/shadow"
fi
log_info "D-Bus user and group configuration verified and any missing entries have been added."


if [ "$BUILD_VARIANT" == "klipperscreen" ]; then
    log_info "Detected 'klipperscreen' build variant. Commencing Klipperscreen-specific setup procedures."
    # Klipperscreen relies heavily on TSLIB for its touchscreen input capabilities.
    # Therefore, the TSLIB configuration is installed as part of its setup.
    install_tslib_requirements
    log_info "Klipperscreen-specific setup successfully completed."

elif [ "$BUILD_VARIANT" == "guppyscreen" ]; then
    log_info "Detected 'guppyscreen' build variant. Commencing Guppyscreen-specific setup procedures."
    # Similar to Klipperscreen, Guppyscreen also utilizes TSLIB for handling
    # touchscreen interactions, so the TSLIB configuration is a prerequisite.
    install_tslib_requirements

    # Create a symbolic link for Guppyscreen's primary configuration file.
    # This crucial link ensures that the runtime configuration file for Guppyscreen
    # is accessible from a user-editable location within the 'printer_data' directory,
    # allowing for easy customization without modifying core system files.
    log_info "  Creating symbolic link for Guppyscreen's main configuration file: /opt/guppyscreen/guppyconfig.json -> /root/printer_data/config/guppyconfig.json. This links the runtime configuration to a user-editable location."
    ln -fs /root/printer_data/config/guppyconfig.json "$TARGET_ROOT/opt/guppyscreen/guppyconfig.json"
    log_info "Guppyscreen-specific setup successfully completed."
else
    log_info "Skipping screen-specific configuration steps."
fi

for overlay in "$BUILD_OVERLAYS"/plugin-*; do
    plugin_name="${overlay##*/plugin-}"
    for target_plugin in "${BUILD_PLUGINS[@]}"; do
        if [[ "$target_plugin" == "$plugin_name" ]]; then
            log_info "Copying $plugin_name plugin overlay to rootfs."
            cp -a "$overlay"/. "$TARGET_ROOT/"
        fi
    done
done

mkdir -p "$BUILD_PACKAGE"

log_info "Copying mcu's firmwares to $(basename $BUILD_PACKAGE) directory..."
cp "$TARGET_ROOT/opt/klipper/firmware"/* "$BUILD_PACKAGE/" || true

log_info "Copying mcu's bootloaders to $(basename $BUILD_PACKAGE) directory..."
cp "$TARGET_ROOT/opt/katapult"/* "$BUILD_PACKAGE/" || true