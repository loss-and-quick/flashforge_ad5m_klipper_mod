#!/bin/sh
#
# Automatically start/stop ustreamer for camera livestream via http
#

CAMERA_DEVNAME=video0
HTTP_PORT=8080
TAG="camera-autostart"
PID_FILE=/run/ustreamer.pid

start() {
    start-stop-daemon -S -b -m -p $PID_FILE --exec ustreamer -- -d /dev/$DEVNAME --device-timeout=2 -w 1 -I MMAP -s* -p 8080
    [ $? -eq 0 ] && logger -t $TAG "started ustreamer for /dev/$DEVNAME" || logger -t $TAG "failed to start ustreamer"
}

stop() {
    start-stop-daemon -K -q -p $PID_FILE
    [ $? -eq 0 ] && logger -t $TAG "stopped ustreamer for /dev/$DEVNAME" || logger -t $TAG "failed to stop ustreamer"
}

if [ "$CAMERA_DEVNAME" == "$DEVNAME" ]
then
    logger -t $TAG "received ACTION=$ACTION /dev/$DEVNAME"

    case "$ACTION" in
        add)
            start
            ;;
        remove)
            stop
            ;;
        *)
            logger -t $TAG "ACTION=$ACTION unsupported"
            exit 1
    esac
fi

exit $?
