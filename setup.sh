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

check_already_setup() {
    if grep -q "#MARKER" /etc/fstab; then
        log "fstab already contains MARKER entry, terminate set up script"
        return 1
    else
        log "MARKER not found in fstab, set up as normal"
        return 0
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
    # setup bind, so it persist reboot
		echo "/opt/nix   /nix   none   bind   0   0" | sudo tee -a /etc/fstab >/dev/null
		log "setting up nix successfully on $MOUNT_DIR/nix"
    return 0
}

clone_dramhit() {
    sudo chown -R "$USER" "$MOUNT_DIR"
    sudo -u "$USER" git clone https://github.com/mars-research/DRAMHiT.git --recursive "$MOUNT_DIR/DRAMHiT"
		log "setting up dramhit successfully on $MOUNT_DIR/DRAMHiT"
    return 0
}

persist_mount() {
    UUID=$(sudo blkid -s UUID -o value "$DISK")
    if [ -z "$UUID" ]; then
        log "ERROR: Failed to retrieve UUID for $DISK"
        return 1
    fi

    FSTAB_ENTRY="UUID=$UUID  $MOUNT_DIR  ext4  defaults  0 2	#MARKER"
    if ! grep -q "$UUID" /etc/fstab; then
        echo "$FSTAB_ENTRY" | sudo tee -a /etc/fstab >/dev/null
		else
				return 1
    fi

		log "Persist mount successfully entry added: $FSTAB_ENTRY"
    return 0
}

main() {
		run_step check_already_setup
		run_step find_unpartitioned_disk
    run_step format_and_mount
    run_step persist_mount
    run_step install_nix
    run_step clone_dramhit
}

main "$@"
