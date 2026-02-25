#!/usr/bin/env bash
set -euo pipefail

# Only on NixOS, otherwise refuse to run
if ! grep -q '^ID=nixos$' /etc/os-release 2>/dev/null; then
  echo "This script must be run from a NixOS installer ISO." >&2
  exit 1
fi

# Check for live ISO, which will have a ro squashfs, if not present then quit!
if ! findmnt -n -o FSTYPE,OPTIONS | grep -q 'squashfs.*ro'; then
  echo "This script can only be run from a NixOS live ISO environment." >&2
  exit 1
fi

if [ "$#" -ne 1 ]; then
  printf 'You must supply the name of the NixOS config you want to install as an argument.\n\n'
  printf 'If the NixOS config you want to use is called example, then type:\n\n'
  printf '   %s example\n' "$0" >&2
  exit 1
fi

# Apply the disko config to the disks
disko --extra-experimental-features "nix-command flakes" -- --mode disko "./hosts/$1/_disko.nix"

# Copy the repository to /mnt and cd into it:
cp -r ../nix-config /mnt/nix-config && cd /mnt/nix-config

# Install NixOS
nixos-install --no-root-password --flake ".#$1"

printf '\n\nInstallation completed, take your USB stick out and restart.'
