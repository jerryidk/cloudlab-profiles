#!/bin/bash

# -------------------------
# Configurable Variables
# -------------------------
MOUNT_DIR="/opt"
USER=jerryidk #cloudlab will run set as geniuser, not actually user, so set your name here.
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


find_unpartitioned_disk() {
    for dev in $(lsblk -dn -o NAME); do
        if ! lsblk /dev/"$dev" | grep -q ├; then
            DISK="/dev/$dev"
						log "found unpartitioned disk: $DISK"
            return 0
        fi
    done
    return 1
}

format_and_mount() {
    sudo mkfs.ext4 "$DISK"
    sudo mkdir -p "$MOUNT_DIR"
    sudo mount "$DISK" "$MOUNT_DIR"
		log "formatting and mount $DISK success!"
    return 0
}

install_nix() {
    sudo mkdir -p /nix "$MOUNT_DIR/nix"
    sudo mount --bind "$MOUNT_DIR/nix" /nix
    yes | sh <(curl -L https://nixos.org/nix/install) --daemon
		log "setting up nix successfully on $MOUNT_DIR/nix"
    return 0
}

clone_dramhit() {
    sudo chown -R "$USER" "$MOUNT_DIR"
    sudo -u "$USER" git clone https://github.com/mars-research/DRAMHiT.git --recursive "$MOUNT_DIR/DRAMHiT"
		log "setting up dramhit successfully on $MOUNT_DIR/DRAMHiT"
    return 0
}


main() {
		run_step find_unpartitioned_disk
    run_step format_and_mount
    run_step install_nix
    run_step clone_dramhit
}

# main "$@"
