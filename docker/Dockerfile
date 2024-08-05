FROM debian:latest AS base

ARG TCP_PORT=16509

# Permission information for 'libvirt'
ARG LIBVIRT_UID=2001
ARG LIBVIRT_GID=2001

# Export env vars
ENV TCP_PORT=${TCP_PORT}
ENV LIBVIRT_UID=${LIBVIRT_UID}
ENV LIBVIRT_GID=${LIBVIRT_GID}

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

# Copy configuration files and base files
COPY --chown=root:libvirt --chmod=770 ./docker/config/* /etc/libvirt
COPY --chown=root:libvirt --chmod=770 ./docker/base /base/

# Subsitute environment variables in configuration
RUN envsubst < /etc/libvirt/libvirtd.conf > /etc/libvirt/libvirtd.conf.tmp && \
    mv /etc/libvirt/libvirtd.conf.tmp /etc/libvirt/libvirtd.conf

# Set up volumes
VOLUME [ \
    "/etc/libvirt/qemu", \
    "/etc/libvirt/storage", \
    "/var/lib/libvirt/images", \
    "/var/log/libvirt/qemu" \
]

# Expose Libvirt TCP port
EXPOSE ${TCP_PORT}

# Copy init.sh and set to run
COPY --chmod=700 ./docker/init.sh /init.sh
CMD ["/init.sh"]