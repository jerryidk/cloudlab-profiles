#!/bin/bash

# -------------------------
# Configurable Variables
# -------------------------
MOUNT_DIR="/opt"
USER=$(logname)
HOME_DIR=$(getent passwd "$USER" | cut -d: -f6)
DISK=$(lsblk -ndo NAME,TYPE | awk '$2=="disk" {print "/dev/"$1; exit}')
LOGFILE="$HOME_DIR/script_log"

# -------------------------
# Logging Utility
# -------------------------
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOGFILE"
}

# -------------------------
# Create partition
# -------------------------
create_partition() {
    log "Creating partition on $DISK"
    echo -e "n\n4\n\n\nw" | fdisk $DISK >> "$LOGFILE" 2>&1
    log "Partition created."
}

# -------------------------
# Format and mount
# -------------------------
format_and_mount() {
    log "Formatting $DISK as ext4..."
    mkfs.ext4 "$DISK" >> "$LOGFILE" 2>&1

    log "Mounting $DISK to $MOUNT_DIR..."
    mkdir -p "$MOUNT_DIR"
    mount "$DISK" "$MOUNT_DIR"
}

# -------------------------
# Install Nix
# -------------------------
install_nix() {
    log "Installing Nix with daemon mode..."
    mkdir -p /nix "$MOUNT_DIR/nix"
    mount --bind "$MOUNT_DIR/nix" /nix

    yes | sh <(curl -L https://nixos.org/nix/install) --daemon >> "$LOGFILE" 2>&1
    log "Nix installation complete."
}

# -------------------------
# Set up direnv
# -------------------------
setup_direnv() {
    log "Installing direnv and enabling flakes..."
    apt update >> "$LOGFILE" 2>&1
    apt install -y direnv >> "$LOGFILE" 2>&1

    mkdir -p "$HOME_DIR/.config/nix"
    echo "experimental-features = nix-command flakes" > "$HOME_DIR/.config/nix/nix.conf"

    if ! grep -q 'direnv hook bash' "$HOME_DIR/.bashrc"; then
        echo 'eval "$(direnv hook bash)"' >> "$HOME_DIR/.bashrc"
    fi
    log "direnv installed and configured."
}

# -------------------------
# Clone DRAMHiT
# -------------------------
clone_dramhit() {
    log "Cloning DRAMHiT into $MOUNT_DIR..."
    chown -R "$USER" "$MOUNT_DIR"
    sudo -u "$USER" git clone https://github.com/mars-research/DRAMHiT.git --recursive "$MOUNT_DIR/DRAMHiT" >> "$LOGFILE" 2>&1
    log "DRAMHiT repository cloned."
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
}

# -------------------------
# Main Execution
# -------------------------
main() {
    create_partition
    format_and_mount
    install_nix
    setup_direnv
    clone_dramhit
    persist_mount
    log "Setup complete. Reboot may be needed."
}

main "$@"
