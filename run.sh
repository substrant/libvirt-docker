#!/usr/bin/env bash

set -e

TCP_PORT=16509

docker build -f ./docker/Dockerfile . --target libvirt \
    -t libvirt-docker:latest \
    --build-arg TCP_PORT=$TCP_PORT \
    --build-arg LIBVIRT_UID=2001 \
    --build-arg LIBVIRT_GID=$(getent group libvirt | cut -d: -f3)

docker run -it --rm \
    --name libvirt-docker \
    --device=/dev/kvm \
    --device=/dev/net/tun \
    -v /proc/sys:/host-procsys:rw \
    --security-opt systempaths=unconfined \
    --security-opt seccomp=unconfined \
    --security-opt apparmor=unconfined \
    --security-opt label:disable \
    --cap-add=SYS_ADMIN \
    --cap-add=NET_ADMIN \
    --cap-add=NET_RAW \
    --cap-add=DAC_OVERRIDE \
    --cap-add=SYS_PTRACE \
    --cgroupns=host \
    -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
    -v ./data/images:/var/lib/libvirt/images \
    -v ./data/log:/var/log/libvirt/qemu \
    -v ./data/qemu:/etc/libvirt/qemu \
    -v ./data/storage:/etc/libvirt/storage \
    -p $TCP_PORT:$TCP_PORT \
    -p 5900-5999:5900-5999 \
    libvirt-docker:latest
