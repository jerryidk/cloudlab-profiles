#!/bin/bash


# -------------------------
# Configurable Variables
# -------------------------
MOUNT_DIR="/opt"
USER=$(whoami)
HOME_DIR=$(getent passwd "$USER" | cut -d: -f6)
LOGFILE="/var/tmp/dramhit-setup.log"
DISK="/dev/nvme2n1"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOGFILE"
}

run_step() {
    "$@"
    local status=$?
    if [ $status -ne 0 ]; then
        log "ERROR: Step '$*' failed with exit code $status"
        exit $status
    fi
}

format_and_mount() {
		log "formatting $DISK and mounting $MOUNT_DIR"
    sudo mkfs.ext4 "$DISK"
    sudo mkdir -p "$MOUNT_DIR"
    sudo mount "$DISK" "$MOUNT_DIR"
		log "success!"
    return 0
}

install_nix() {
    sudo mkdir -p /nix "$MOUNT_DIR/nix"
    sudo mount --bind "$MOUNT_DIR/nix" /nix
    yes | sh <(curl -L https://nixos.org/nix/install) --daemon >>"$LOGFILE" 2>&1
    return 0
}

clone_dramhit() {
    sudo chown -R "$USER" "$MOUNT_DIR"
    sudo -u "$USER" git clone https://github.com/mars-research/DRAMHiT.git --recursive "$MOUNT_DIR/DRAMHiT" >>"$LOGFILE" 2>&1
    return 0
}

persist_mount() {
    UUID=$(sudo blkid -s UUID -o value "$DISK")
    if [ -z "$UUID" ]; then
        log "ERROR: Failed to retrieve UUID for $DISK"
        return 1
    fi

    FSTAB_ENTRY="UUID=$UUID  $MOUNT_DIR  ext4  defaults  0 2"
    if ! grep -q "$UUID" /etc/fstab; then
        echo "$FSTAB_ENTRY" | sudo tee -a /etc/fstab >/dev/null
		else
				return 1
    fi

    return 0
}

main() {
    run_step format_and_mount
    run_step persist_mount
    run_step install_nix
    run_step clone_dramhit
}

main "$@"
