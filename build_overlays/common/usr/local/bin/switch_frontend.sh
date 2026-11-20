#!/bin/sh
#
# switch_frontend.sh — switch or toggle between Fluidd and Mainsail
#
# Both frontends are served by nginx on port 4000 from /var/www/frontend, which
# is a symlink to the selected webroot. The executable bit of S70fluidd and
# S70mainsail is the selection state, since rcS starts the one that is
# executable.
#

# Klipper runs shell commands with a minimal environment, which has no sbin
# directories where start-stop-daemon lives.
PATH=/usr/sbin:/usr/bin:/sbin:/bin
export PATH

INIT_DIR="/etc/init.d"
FLUIDD_INIT="${INIT_DIR}/S70fluidd"
MAINSAIL_INIT="${INIT_DIR}/S70mainsail"
NGINX_INIT="${INIT_DIR}/S70nginx"
FRONTEND_LINK=/var/www/frontend
LOGFILE="/var/log/frontend_switch.log"

log_message() {
    now=$(date '+%Y-%m-%d %H:%M:%S')
    echo "${now} - $1" | tee -a "${LOGFILE}"
}

# Explicit modes: a symbolic chmod honours the umask and can leave a stray
# execute bit, which made the state check report the wrong frontend.
enable_frontend() {
    chmod 755 "$1"
}

disable_frontend() {
    chmod 644 "$1"
}

serve() {
    webroot="$1"
    name="$2"

    mkdir -p /var/www
    ln -sfn "$webroot" "$FRONTEND_LINK"

    # Reload through the init script so the pid file stays authoritative.
    "$NGINX_INIT" restart >/dev/null 2>&1

    if [ -s /run/nginx.pid ] && kill -0 "$(cat /run/nginx.pid)" 2>/dev/null; then
        log_message "${name} is now served from ${webroot}."
    else
        log_message "ERROR: nginx failed to start for ${name}."
    fi
}

switch_to_fluidd() {
    log_message "Switching to Fluidd"
    disable_frontend "$MAINSAIL_INIT"
    enable_frontend "$FLUIDD_INIT"
    serve /opt/fluidd "Fluidd"
}

switch_to_mainsail() {
    log_message "Switching to Mainsail"
    disable_frontend "$FLUIDD_INIT"
    enable_frontend "$MAINSAIL_INIT"
    serve /opt/mainsail "Mainsail"
}

usage() {
    echo "Usage: $0 [fluidd|mainsail|toggle]"
    echo "  no arguments or 'toggle' = switch to the other frontend"
    exit 1
}

for script in "$FLUIDD_INIT" "$MAINSAIL_INIT" "$NGINX_INIT"; do
    if [ ! -f "$script" ]; then
        log_message "ERROR: init-script '$script' not found!"
        exit 1
    fi
done

case "$1" in
    ""|toggle)
        if [ -x "$FLUIDD_INIT" ]; then
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
