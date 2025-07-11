#!/bin/sh
#
# switch_frontend.sh — switch or toggle between Fluidd and Mainsail web frontends
#

INIT_DIR="/etc/init.d"
FLUIDD_INIT="${INIT_DIR}/S70fluidd"
MAINSAIL_INIT="${INIT_DIR}/S70mainsail"
LOGFILE="/var/log/frontend_switch.log"

# Log a message with timestamp
log_message() {
    now=$(date '+%Y-%m-%d %H:%M:%S')
    echo "${now} - $1" | tee -a "${LOGFILE}"
}

ensure_scripts_exist() {
    for script in "${FLUIDD_INIT}" "${MAINSAIL_INIT}"; do
        if [ ! -f "$script" ]; then
            log_message "ERROR: init-script '$script' not found!"
            exit 1
        fi
    done
}

# Switch to Fluidd
switch_to_fluidd() {
    log_message "Switching to Fluidd"
    if [ -x "${MAINSAIL_INIT}" ]; then
        log_message "Stopping Mainsail..."
        "${MAINSAIL_INIT}" stop 2>/dev/null
        chmod -x "${MAINSAIL_INIT}"
        log_message "Mainsail stopped and disabled."
    fi

    if [ ! -x "${FLUIDD_INIT}" ]; then
        log_message "Starting Fluidd..."
        chmod +x "${FLUIDD_INIT}"
        "${FLUIDD_INIT}" start 2>/dev/null
        log_message "Fluidd started and enabled."
    else
        log_message "Fluidd is already active."
    fi
    log_message "Fluidd is now active"
}

# Switch to Mainsail
switch_to_mainsail() {
    log_message "Switching to Mainsail"
    if [ -x "${FLUIDD_INIT}" ]; then
        log_message "Stopping Fluidd..."
        "${FLUIDD_INIT}" stop 2>/dev/null
        chmod -x "${FLUIDD_INIT}"
        log_message "Fluidd stopped and disabled."
    fi

    if [ ! -x "${MAINSAIL_INIT}" ]; then
        log_message "Starting Mainsail..."
        chmod +x "${MAINSAIL_INIT}"
        "${MAINSAIL_INIT}" start 2>/dev/null
        log_message "Mainsail started and enabled."
    else
        log_message "Mainsail is already active."
    fi
    log_message "Mainsail is now active"
}

# Check and correct invalid states:
# - both init scripts executable
# - neither init script executable
check_frontend_state() {
    fluidd_on=0
    mainsail_on=0

    [ -x "${FLUIDD_INIT}" ] && fluidd_on=1
    [ -x "${MAINSAIL_INIT}" ] && mainsail_on=1

    if [ "$fluidd_on" -eq 1 ] && [ "$mainsail_on" -eq 1 ]; then
        log_message "WARNING: Both Fluidd and Mainsail are enabled!"
        log_message "Disabling Mainsail to keep only Fluidd."
        "${MAINSAIL_INIT}" stop 2>/dev/null
        chmod -x "${MAINSAIL_INIT}"
        log_message "Mainsail disabled."
    fi

    if [ "$fluidd_on" -eq 0 ] && [ "$mainsail_on" -eq 0 ]; then
        log_message "WARNING: Neither frontend is enabled."
        log_message "Defaulting to Fluidd."
        chmod +x "${FLUIDD_INIT}"
        log_message "Fluidd enabled."
    fi
}

# Print usage and exit
usage() {
    echo "Usage: $0 [fluidd|mainsail|toggle]"
    echo "  no arguments or 'toggle' = switch to the other frontend"
    exit 1
}

ensure_scripts_exist
check_frontend_state

case "$1" in
    ""|toggle)
        if [ -x "${FLUIDD_INIT}" ]; then
            switch_to_mainsail
        else
            switch_to_fluidd
        fi
        ;;
    fluidd)
        switch_to_fluidd
        ;;
    mainsail)
        switch_to_mainsail
        ;;
    *)
        log_message "Unknown argument: $1"
        usage
        ;;
esac

exit 0
