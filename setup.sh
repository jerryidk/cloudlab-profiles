#!/bin/bash

MOUNT_DIR="/opt"
sudo mkdir -p /nix "$MOUNT_DIR/nix"
sudo mount --bind "$MOUNT_DIR/nix" /nix
yes | sh <(curl -L https://nixos.org/nix/install) --daemon
