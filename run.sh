docker build -f ./docker/Dockerfile . --target libvirt \
    -t libvirt-docker:latest \
    --build-arg LIBVIRT_UID=2001 \
    --build-arg LIBVIRT_GID=$(getent group libvirt | cut -d: -f3)

docker run -it --rm --privileged \
    -v ./images:/var/lib/libvirt/images \
    -v ./log:/var/log/libvirt/qemu \
    -v ./qemu:/etc/libvirt/qemu \
    -v ./storage:/etc/libvirt/storage \
    --cgroupns host \
    -p 16509:16509 \
    -p 5900:5900 \    # testing spice
    libvirt-docker:latest