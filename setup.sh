#!/bin/bash

# sda4 is the disk. need to set this up as MOUNT_DIR 
MOUNT_DIR=/opt/mnt
USER=jerryidk # CHANGE ME

# ensures sudo privilege
if [[ ${SUDO_GID} == "" ]]; then
  GROUP=$(id -g -n)
fi

# format filesystem and mount 
sudo mkfs.ext4 /dev/sda4
sudo mkdir -p ${MOUNT_DIR}
sudo mount /dev/sda4 ${MOUNT_DIR}

# permission
sudo chown -R ${USER} ${MOUNT_DIR}

# update apt just in case  
sudo apt update

# OPTIONAL install nix.
sudo mkdir -p /nix
sudo mkdir -p ${MOUNT_DIR}/nix
sudo mount -o bind ${MOUNT_DIR}/nix /nix
sh <(curl -L https://nixos.org/nix/install) --no-daemon
