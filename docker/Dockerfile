FROM debian:latest AS base

# Permission information for 'libvirt'
ARG LIBVIRT_UID=2001
ARG LIBVIRT_GID=2001

# Update package lists and install necessary tools
RUN apt-get update && apt-get install -y --no-install-recommends \
        cgroup-tools \
        dmidecode \
        iproute2 \
        ipxe-qemu \
        kmod \
        libvirt-daemon-system \
        libvirt-clients \
        openssh-client \
        openvswitch-switch \
        pm-utils \
        qemu-efi \
        qemu-block-extra \
        qemu-kvm \
        qemu-utils \
        qemu-system \
        ovmf \
        virtinst \
        dbus \
        netcat-openbsd \
        bridge-utils \
        dnsmasq \
        iptables \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set up group and user
RUN groupmod -g ${LIBVIRT_GID} libvirt && \
    useradd -u ${LIBVIRT_UID} -g ${LIBVIRT_GID} -s /bin/bash -m libvirt

##########################################################################################
FROM base AS libvirt

# Ensure all config folders exist
RUN mkdir -p \
    /etc/libvirt/qemu/networks \
    /etc/libvirt/storage

# Copy configuration files and directories
COPY --chown=root:libvirt --chmod=770 ./docker/libvirtd.conf /etc/libvirt/libvirtd.conf
COPY --chown=root:libvirt --chmod=770 ./docker/network.conf /etc/libvirt/network.conf

# Set up volumes
VOLUME /etc/libvirt/qemu
VOLUME /etc/libvirt/storage
VOLUME /var/lib/libvirt/images
VOLUME /var/log/libvirt/qemu

# Expose Libvirt TCP port
EXPOSE 16509

# Copy init.sh and set to run
COPY --chmod=700 ./docker/init.sh /init.sh
CMD ["/init.sh"]