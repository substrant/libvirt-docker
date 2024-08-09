#!/bin/bash

# There's gonna be some stupid error if we don't use redhat's daemon
dbus-daemon --system --fork

# Other daemons need to run too because stuff wont work
virtlockd &        # detaching like this might constipate linux, fix l8r
virtlogd &

# If we have permission, check if KVM is loaded
if ! [ -e /dev/kvm ]; then
    # Load KVM
    echo "Loading KVM module..."
    modprobe kvm

    # Load KVM for the specific CPU manufacturer
    cpu_manufacturer=$(lscpu | grep -o "GenuineIntel\|AuthenticAMD")
    echo "Loading KVM module for $cpu_manufacturer..."

    # Load the correct module corresponding to the CPU
    if [ "$cpu_manufacturer" = "GenuineIntel" ]; then
        modprobe kvm_intel
    elif [ "$cpu_manufacturer" = "AuthenticAMD" ]; then
        modprobe kvm_amd
    else
        echo "Unsupported CPU manufacturer"
    fi
fi

# Create bind mount from /host-procsys to /proc/sys
mount --bind /host-procsys /proc/sys

# Set up the rest of the configuration crap that's on volumes
# Yes, I know that this isn't ideal and that I should use virsh.
# Can't care to fix it - it works fine for me and I dont see a reason to change it.

if [ ! -e "/etc/libvirt/qemu/storage/default.xml" ]; then
    storage_default=1
    mkdir -p /etc/libvirt/qemu/storage/autostart
    cp /base/storage-default.xml /etc/libvirt/qemu/storage/default.xml
fi

if [ ! -e "/etc/libvirt/qemu/networks/default.xml" ]; then
    network_default=1
    mkdir -p /etc/libvirt/qemu/networks/autostart
    cp /base/network-default.xml /etc/libvirt/qemu/networks/default.xml
fi

# Clean up the base directory
rm -rf /base

# Set up permissions
chown -R "$LIBVIRT_UID:$LIBVIRT_GID" /var/lib/libvirt/images
chmod -R 775 /var/lib/libvirt/images

chown -R "$LIBVIRT_UID:$LIBVIRT_GID" /var/log/libvirt/qemu
chmod -R 755 /var/log/libvirt/qemu

# Btw this will vomit a crap ton of udev errors but it shouldnt be a problem
# idk why it does this but it hasnt caused an issue where i need to fix anything...yet
libvirtd -l -f /etc/libvirt/libvirtd.conf &
libvird_daemon_pid=$!

# Wait on libvirt to start up
while ! nc -z 127.0.0.1 $TCP_PORT; do
    sleep 1
done

# Virsh do some cool stuff here
if [ "$storage_default" = 1 ]; then
    virsh pool-autostart default
    virsh pool-start default
fi

if [ "$network_default" = 1 ]; then
    virsh net-autostart default
    virsh net-start default
fi

# And now we wait for the daemon to die
wait $libvird_daemon_pid