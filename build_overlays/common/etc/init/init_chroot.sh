#!/bin/sh
# "Init" process for chroot environment

mkdir -p /dev/shm
mkdir -p /run/lock/subsys

# load kernel modules if built as modular
modprobe cbc 2>/dev/null || true
modprobe md4 2>/dev/null || true
modprobe sha512_generic 2>/dev/null || true
modprobe 8821cu 2>/dev/null || true
modprobe uinput 2>/dev/null || true

# mount swap
sysctl vm.swappiness=15
swapon /mnt/swap
# set hostname
hostname -F /etc/hostname
# restore last known time
fake-hwclock load

# start chroot init scripts
/etc/init.d/rcS

exit 0
