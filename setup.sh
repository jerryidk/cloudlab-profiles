#!/bin/bash

set -euo pipefail

run_step() {
    "$@"
    local status=$?
    if [ $status -ne 0 ]; then
        log "ERROR: Step '$*' failed with exit code $status"
        exit $status
    fi
}

# -------------------------
# Configurable Variables
# -------------------------
MOUNT_DIR="/opt"
USER=$(logname)
HOME_DIR=$(getent passwd "$USER" | cut -d: -f6)
LOGFILE="/dev/console"
DISK=""

# -------------------------
# Logging Utility
# -------------------------
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOGFILE"
}


find_unpartitioned_disk() {
    for dev in $(lsblk -dn -o NAME); do
        if ! lsblk /dev/"$dev" | grep -q ├; then
            DISK="/dev/$dev"
						return 0
        fi
    done
		return 1
}

format_and_mount() {
    mkfs.ext4 "$DISK" >> "$LOGFILE" 2>&1
    mkdir -p "$MOUNT_DIR"
    mount "$DISK" "$MOUNT_DIR"
		return 0
}

# -------------------------
# Install Nix
# -------------------------
install_nix() {
    log "Installing Nix with daemon mode..."
    mkdir -p /nix "$MOUNT_DIR/nix"
    mount --bind "$MOUNT_DIR/nix" /nix
    yes | sh <(curl -L https://nixos.org/nix/install) --daemon >> "$LOGFILE" 2>&1
		return 0
}

# -------------------------
# Set up direnv
# -------------------------
setup_direnv() {
    apt update >> "$LOGFILE" 2>&1
    apt install -y direnv >> "$LOGFILE" 2>&1
    mkdir -p "$HOME_DIR/.config/nix"
    echo "experimental-features = nix-command flakes" > "$HOME_DIR/.config/nix/nix.conf"
    if ! grep -q 'direnv hook bash' "$HOME_DIR/.bashrc"; then
        echo 'eval "$(direnv hook bash)"' >> "$HOME_DIR/.bashrc"
    fi
		return 0
}

# -------------------------
# Clone DRAMHiT
# -------------------------
clone_dramhit() {
    chown -R "$USER" "$MOUNT_DIR"
    sudo -u "$USER" git clone https://github.com/mars-research/DRAMHiT.git --recursive "$MOUNT_DIR/DRAMHiT" >> "$LOGFILE" 2>&1
		return 0
}

# -------------------------
# Persist mount in fstab
# -------------------------
persist_mount() {
    UUID=$(sudo blkid -s UUID -o value "$DISK")
    if [ -z "$UUID" ]; then
        log "ERROR: Failed to retrieve UUID for $DISK"
        exit 1
    fi

    FSTAB_ENTRY="UUID=$UUID  $MOUNT_DIR  ext4  defaults  0 2"
    if ! grep -q "$UUID" /etc/fstab; then
        echo "$FSTAB_ENTRY" | sudo tee -a /etc/fstab > /dev/null
        log "fstab entry added: $FSTAB_ENTRY"
    else
        log "fstab entry already exists for $UUID"
    fi

		return 0
}

# -------------------------
# Main Execution
# -------------------------
main() {
		run_step find_unpartitioned_disk
    # run_step create_partition
    run_step format_and_mount
    run_step install_nix
    run_step setup_direnv
    run_step clone_dramhit
    run_step persist_mount
}

main "$@"
