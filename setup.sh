#!/bin/bash

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

# permission
sudo chown -R ${USER} ${MOUNT_DIR}

# update apt just in case  
sudo apt update

# install nix.
sudo mkdir -p /nix
sudo mkdir -p ${MOUNT_DIR}/nix
sudo mount -o bind ${MOUNT_DIR}/nix /nix
yes | sh <(curl -L https://nixos.org/nix/install) --daemon

# set up nix 
sudo mkdir -p ~/.config/nix
touch ~/.config/nix/nix.conf
echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf

# direnv
sudo apt install direnv
echo "eval $(direnv hook bash)" >> ~/.bashrc 

cd ${MOUNT_DIR}
git clone git@github.com:mars-research/DRAMHiT.git --recursive

cd ${MOUNT_DIR}/DRAMHiT/tools/msr-safe
make 
sudo insmod msr-safe.ko

cd ${MOUNT_DIR}/DRAMHiT/
sudo ./scripts/setup.sh
