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

# set up fs for user
sudo mkdir -p ${MOUNT_DIR}/users/${USER}
sudo mount -o bind ${MOUNT_DIR}/users/${USER} /users/${USER}

# set up fs for nix
sudo mkdir -p /nix
sudo mkdir -p ${MOUNT_DIR}/nix
sudo mount -o bind ${MOUNT_DIR}/nix /nix

# permission
sudo chown +R ${USER} ${MOUNT_DIR}

# update apt just in case  
sudo apt update

# install nix single user
sh <(curl -L https://nixos.org/nix/install) --no-daemon
. ~/.nix-profile/etc/profile.d/nix.sh

# clone your repos here
