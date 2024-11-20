#!/bin/bash

set -eo pipefail

MOUNT_DIR=/opt/mnt
NIX_DAEMON_VARS="/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
NIX_NO_DAEMON_VARS="$HOME/.nix-profile/etc/profile.d/nix.sh"
LOG_FILE=/logs.txt
SUDO_USER=jerryidk #!CHANGE ME

USER=${SUDO_USER}

if [[ ${USER} == "" ]]; then
  USER=$(id -u -n)
fi

if [[ ${SUDO_GID} == "" ]]; then
  GROUP=$(id -g -n)
else
  GROUP=$(getent group  | grep ${SUDO_GID} | cut -d':' -f1)
fi

record_log() {
  echo "[$(date)] $1" >> ${LOG_FILE}
}

install_nix_daemon() {
  if [ ! -x "$(command -v nix-channel)" ]; then
    sh <(curl -L https://nixos.org/nix/install) --daemon
    if [ -f ${NIX_DAEMON_VARS} ]; then
      echo "sourcing ${NIX_DAEMON_VARS}"
      source ${NIX_DAEMON_VARS}
    fi
  else
    record_log "Nix already installed!";
  fi
}

install_dependencies() {
  record_log "Installing nix..."
  install_nix_daemon
  nix-channel --list
}

create_extfs() {
  record_log "Creating ext4 filesystem on /dev/sda4"
  sudo mkfs.ext4 -Fq /dev/sda4
}

mountfs() {
  sudo mkdir -p ${MOUNT_DIR}
  sudo mount -t ext4 /dev/sda4 ${MOUNT_DIR}

  if [[ $? != 0 ]]; then
    record_log "Partition might be corrupted"
    create_extfs
    mountfs
  fi

  sudo chown -R ${USER}:${GROUP} ${MOUNT_DIR}
}

prepare_local_partition() {

  MOUNT_POINT=$(mount -v | grep "/dev/sda4" | awk '{print $3}' ||:)

  if [[ x"${MOUNT_POINT}" == x"${MOUNT_DIR}" ]];then
    return
  fi

  if [ x$(sudo file -sL /dev/sda4 | grep -o ext4) == x"" ]; then
    create_extfs;
  fi

  mountfs
}

prepare_machine() {
  prepare_local_partition

  sudo mkdir /nix
  sudo cp -r /nix ${MOUNT_DIR}
  sudo mount --bind ${MOUNT_DIR}/nix /nix

  install_dependencies
}

prepare_machine;
sudo ln -s $(which nix-store) /usr/local/bin/nix-store
record_log "Done Setting up!"
