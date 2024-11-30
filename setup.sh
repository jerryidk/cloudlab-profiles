#!/bin/bash

MOUNT_DIR=/opt/mnt
USER=jerryidk

# set sudo privilege
if [[ ${SUDO_GID} == "" ]]; then
  GROUP=$(id -g -n)
fi

# format filesystem and mount 
sudo mkfs.ext4 /dev/sda4
sudo mkdir -p ${MOUNT_DIR}
sudo mount /dev/sda4 ${MOUNT_DIR}

# install nix
sudo mkdir /nix
sudo mount --bind ${MOUNT_DIR}/nix /nix
sh <(curl -L https://nixos.org/nix/install) --no-daemon

# user mount
sudo mount ${MOUNT_DIR}/users/${USER} /users/${USER}
