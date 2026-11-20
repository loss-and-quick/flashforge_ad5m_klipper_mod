#!/bin/sh
#
# switch_frontend.sh — switch or toggle between Fluidd and Mainsail web frontends
#

# Klipper starts shell commands with a minimal environment, which does not
# include the sbin directories where start-stop-daemon lives.
PATH=/usr/sbin:/usr/bin:/sbin:/bin
export PATH

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

# Use explicit modes: a symbolic "chmod +x" keeps bits the umask allows and
# leaves the script looking executable to "test -x", which used to make the
# switch a no-op and left no frontend running at all.
enable_frontend() {
    chmod 755 "$1"
}

disable_frontend() {
    chmod 644 "$1"
}

is_enabled() {
    [ -x "$1" ]
}

# busybox pgrep has no -f, so track the frontend through the pid files that the
# init scripts write with start-stop-daemon -m.
httpd_running() {
    for pidfile in /run/httpd_fluidd.pid /run/httpd_mainsail.pid; do
        if [ -s "$pidfile" ] && kill -0 "$(cat "$pidfile")" 2>/dev/null; then
            return 0
        fi
    done
    return 1
}

stop_frontend() {
    if [ -f "$1" ]; then
        "$1" stop >/dev/null 2>&1
    fi
}

# busybox httpd keeps per-connection children that inherit the listening
# socket, so stopping the pid from the pid file leaves the port held and the
# next frontend silently serves nothing. Stop by command line instead.
stop_httpd() {
    for proc in /proc/[0-9]*; do
        cmdline=$(tr '\0' ' ' < "$proc/cmdline" 2>/dev/null) || continue
        case "$cmdline" in
            *httpd*4000*)
                kill "$(basename "$proc")" 2>/dev/null
                ;;
        esac
    done
    sleep 1
    for proc in /proc/[0-9]*; do
        cmdline=$(tr '\0' ' ' < "$proc/cmdline" 2>/dev/null) || continue
        case "$cmdline" in
            *httpd*4000*)
                kill -9 "$(basename "$proc")" 2>/dev/null
                ;;
        esac
    done
    sleep 1
}

# Only one of the two init scripts may be executable, because rcS starts every
# executable S?? script and both serve port 4000.
start_frontend() {
    local script="$1"
    local name="$2"

    enable_frontend "$script"
    "$script" start >/dev/null 2>&1

    # busybox httpd silently exits when the port is still held by a dying
    # instance, so wait for it and retry once.
    sleep 1
    if ! httpd_running; then
        log_message "httpd did not start, retrying ${name}..."
        stop_httpd
        "$script" start >/dev/null 2>&1
        sleep 1
    fi

    if httpd_running; then
        log_message "${name} started and enabled."
    else
        log_message "ERROR: ${name} failed to start, port 4000 is not served."
    fi
}

switch_to_fluidd() {
    log_message "Switching to Fluidd"
    stop_frontend "$MAINSAIL_INIT"
    stop_frontend "$FLUIDD_INIT"
    disable_frontend "$MAINSAIL_INIT"
    stop_httpd
    start_frontend "$FLUIDD_INIT" "Fluidd"
}

switch_to_mainsail() {
    log_message "Switching to Mainsail"
    stop_frontend "$FLUIDD_INIT"
    stop_frontend "$MAINSAIL_INIT"
    disable_frontend "$FLUIDD_INIT"
    stop_httpd
    start_frontend "$MAINSAIL_INIT" "Mainsail"
}

usage() {
    echo "Usage: $0 [fluidd|mainsail|toggle]"
    echo "  no arguments or 'toggle' = switch to the other frontend"
    exit 1
}

ensure_scripts_exist

case "$1" in
    ""|toggle)
        if is_enabled "${FLUIDD_INIT}"; then
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
