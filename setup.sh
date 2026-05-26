#!/bin/bash

MOUNT_DIR="/opt"

# Installing nix
sudo mkdir -p /nix "$MOUNT_DIR/nix"
sudo mount --bind "$MOUNT_DIR/nix" /nix
yes | sh <(curl -L https://nixos.org/nix/install) --daemon

sudo apt update
sudo apt install gh cmake-curses-gui

