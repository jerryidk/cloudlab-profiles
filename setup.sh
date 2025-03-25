#!/bin/bash

set -e
# Note: cloudlab boot user with 16GB boot partiiton
# sda4 has more storage, need to set this up as MOUNT_DIR 
MOUNT_DIR=/opt
USER=jerryidk # CHANGE ME
DISK=/dev/nvme0n1p4 # CHANGE ME

# ensures sudo privilege
if [[ ${SUDO_GID} == "" ]]; then
  GROUP=$(id -g -n)
fi

# format filesystem and mount 
sudo mkfs.ext4 ${DISK}
sudo mkdir -p ${MOUNT_DIR}
sudo mount ${DISK} ${MOUNT_DIR}

# install nix.
sudo mkdir -p /nix
sudo mkdir -p ${MOUNT_DIR}/nix
sudo mount --bind ${MOUNT_DIR}/nix /nix
yes | sh <(curl -L https://nixos.org/nix/install) --daemon

sudo apt update
sudo apt install direnv

mkdir -p ~/.config/nix
touch ~/.config/nix/nix.conf
echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf
echo "eval $(direnv hook bash)" >> ~/.bashrc 

source ~/.bashrc

sudo chown -R ${USER} ${MOUNT_DIR}
cd ${MOUNT_DIR}
git clone https://github.com/mars-research/DRAMHiT.git --recursive

cd ${MOUNT_DIR}/DRAMHiT/
direnv allow .
sudo ./scripts/setup.sh

UUID=$(sudo blkid -s UUID -o value $DEVICE)
if [ -z "$UUID" ]; then
    echo "Failed to retrieve UUID for $DEVICE"
    exit 1
fi

FSTAB_ENTRY="UUID=$UUID  $MOUNT_DIR  ext4  defaults  0 2"
echo "Adding the following line to /etc/fstab:"
echo "$FSTAB_ENTRY"
echo "$FSTAB_ENTRY" | sudo tee -a /etc/fstab > /dev/null
