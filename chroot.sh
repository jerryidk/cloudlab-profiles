#!/bin/bash

set -e  # Exit on any error

# Define source and destination devices
DISK=/dev/nvme0n1p4 # CHANGE ME
SRC_DEV="/dev/nvme0n1p1"
DST_DEV="/dev/nvme0n1p4"
MOUNT_DIR="/opt"

# Ensures sudo privilege
if [[ ${SUDO_GID} == "" ]]; then
  GROUP=$(id -g -n)
fi

# Check running as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

echo "Partitioning and formatting $DST_DEV..."
sudo mkfs.ext4 ${DST_DEV}

echo "Mounting $DST_DEV at $MOUNT_DIR..."
sudo mkdir -p ${MOUNT_DIR}
sudo mount ${DST_DEV} ${MOUNT_DIR}

echo "Copying filesystem from $SRC_DEV to $DST_DEV..."
sudo rsync -aAXv /* ${MOUNT_DIR} --exclude={/dev/*,/proc/*,/sys/*,/tmp/*,/run/*,/mnt/*,/media/*,/lost+found}

echo "Updating fstab..."
UUID=$(blkid -s UUID -o value ${DST_DEV})
echo "UUID=${UUID} / ext4 defaults 0 1" | sudo tee ${MOUNT_DIR}/etc/fstab

echo "Setting up chroot..."
sudo mount --bind /dev ${MOUNT_DIR}/dev
sudo mount --bind /proc ${MOUNT_DIR}/proc
sudo mount --bind /sys ${MOUNT_DIR}/sys
sudo mount --bind /run ${MOUNT_DIR}/run

echo "Chrooting into new system..."
sudo chroot ${MOUNT_DIR} /bin/bash

echo "Done. You are now inside the new root filesystem."
