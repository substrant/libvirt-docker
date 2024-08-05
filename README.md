# libvirt-docker

This is a Docker image that runs libvirt and exposes its API over a TCP socket. It is
based on the official Debian image and is intended to run a system libvirt daemon in a
form that is able to be containerized.

Intended implementation for this image is to run virtual networks and a KVM hypervisor
through a container. This is useful for maintaining a uniform environment for systems that
are dedicated Docker hosts.

## Features

The following features have been tested and are confirmed to work:
- KVM virtualization
- Booting virtual machines from ISOs

## Definitions

Modes are described using the octal notation for file permissions. The notation is
described through a bitmask that represents the permissions for the owner, group, and
others. The following table describes the notation:

| Bit | Permission | Action  |
|-----|------------|---------|
| 000 | ---        | N/A     |
| 001 | --x        | Execute |
| 010 | -w-        | Write   |
| 100 | r--        | Read    |

It is noted that the permissions are represented in the respective order of owner, group,
and others, starting from the MSB. Permissions can be stacked by adding the respective
values together. For example, `rwx` is represented as `111` in binary, which is `7` in
octal notation, and it grants read, write, and execute permissions to everyone on the
system.

## Image Parameters

The following parameters can be set when building the image:

| Parameter      | Description                                     | Default |
|----------------|-------------------------------------------------|---------|
| LIBVIRT_UID    | The user ID for the libvirt user                | 2001    |
| LIBVIRT_GID    | The group ID for the libvirt group              | 2001    |
| TCP_PORT       | The port to expose the libvirt API over TCP     | 16509   |

The `LIBVIRT_UID` and `LIBVIRT_GID` parameters are used to set the user and group IDs for
accessing files exposed by the container. 

## Exposed Volumes

The following volumes are exposed by the container and are intended to be accessed from
the host if necessary:

| Volume                  | Description                        | Mode |
|-------------------------|------------------------------------| -----|
| /var/lib/libvirt/images | Storage for virtual machine images | 775  |
| /var/log/libvirt/qemu   | Log files for libvirt QEMU         | 755  |

When the Docker container is started, the ownership of all files and directories in
`/var/lib/libvirt/images` will be set to the user and group `libvirt` on the container,
which may pertain to the [Dockerfile parameters](#image-parameters).

Additionally, the following volumes are exposed for auxiliary purposes but are not
recommended for use. They exist only to provide persistent storage for configuration
files. If you want to configure libvirt, you should do so through `virsh` or a similar
libvirt frontend.

| Volume                  | Description                        | Mode |
|-------------------------|------------------------------------| -----|
| /etc/libvirt/qemu       | Additional libvirt configuration   | 775  |
| /etc/libvirt/storage    | Libvirt storage pool configuration | 755  |

## Default Configuration

A default network and storage pool are created and started when the container is started.
They are defined in [./docker/base](./docker/base) for your reference. The container will
not overwrite these configurations if they already exist, so you can modify them to your
requirements.

## Container Permissions

Since libvirt requires direct access to certain devices on the host, you will need to
explicitly expose these devices to the container. There are two ways to do this, one is
more secure than the other, and the other is more convenient but not practical for use
in production.

### 1. Exposing interfaces and granting permissions

For full functionality of KVM, you should mount the following devices and paths to the
container. This will allow the container to properly interact with the host's kernel.

The following tables were compiled together with a combination of reverse engineering and
trial and error. They are not exhaustive and may not be entirely accurate. These should be
enough to get basic networking and KVM virtualization working.

#### Devices and Interfaces

| Expose            | Mode | Function                     | Required |
|-------------------|------|------------------------------|----------|
| /proc/sys:rw      | 700  | Kernel configuration         | Yes*     |
| /dev/kvm:rw       | 700  | Kernel Virtual Machine (KVM) | No       |
| /sys/fs/cgroup:rw | 700  | Control group management     | No       |
| /dev/net/tun:rw   | 700  | Virtual TAP interfaces       | No       |

\* The `/proc/sys` directory should be exposed to the container as `/host_procsys`. The
container will handle binding the directory to `/proc/sys` when it starts.

#### Capabilities

| Capability   | Function                  | Required       |
|--------------|---------------------------|----------------|
| SYS_ADMIN    | Kernel configuration      | Required       |
| SYS_PTRACE   | Arbitrary memory transfer | Required       |
| SYS_MODULE   | Loading kernel modules*   | Recommended    |
| DAC_OVERRIDE | Bypass file permissions   | Discretionary  |
| NET_ADMIN    | Virtual networking        | Discretionary  |
| NET_RAW      | Low level networking      | Discretionary  |

\* The `SYS_MODULE` capability is not strictly required, but it is recommended to allow
the container to load kernel modules if necessary.

While this exposes the container to the host, it narrows the attack surface to only the
devices and paths that are necessary for the container to function. This is the
recommended way to run the container, because running the container in privileged mode
will expose the container to the entire host without any restrictions.

#### AppArmor and SELinux (Not Tested)

If you are using AppArmor or SELinux, you will need to configure additional security
policies to allow the container to access the necessary devices and paths.

Ideally, you would not want to bypass these security mechanisms. If you are unable to
develop policies that allow the container to access the necessary devices, you can disable
the security mechanisms entirely to allow the container to run without strict policies.

This is not tested, but it should be possible to bypass the security policies with the
following configuration:

- **AppArmor**: Set the security option `apparmor` to `unconfined`.
- **SELinux**: Set the security option `label` to `unconfined`.

It is not recommended to disable these security mechanisms if you happen to be using them
in your server environment.

#### Additional Security Options

In order for the container to run properly, you may need to set the following security
options:

| Option         | Value      | Description                       |
|----------------|------------|-----------------------------------|
| systempaths    | unconfined | Allow access to host system paths |
| seccomp        | unconfined | Disable seccomp filtering*        |

\* Disabling `seccomp` will grant the container extended privileges on already-open file
descriptors

### 2. Runnning the container in privileged mode

**This is not recommended for practical use.**

The previously mentioned capabilities are not an exhaustive list and have been determined
through trial and error. If you are unsure about the capabilities required for your use
case, you can run the container in privileged mode. This will grant the container full
access to the host's devices and kernel, but it will also disable all security mechanisms
that Docker provides. 

