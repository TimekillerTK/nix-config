#!/usr/bin/env bash
set -euo pipefail

# Only on NixOS, otherwise refuse to run
if ! grep -q '^ID=nixos$' /etc/os-release 2>/dev/null; then
  echo "This script must be run from a NixOS installer ISO."
  exit 1
fi

# Check for live ISO, which will have a ro squashfs, if not present then quit!
if ! findmnt -n -o FSTYPE,OPTIONS | grep -q 'squashfs.*ro'; then
  echo "This script can only be run from a NixOS live ISO environment."
  exit 1
fi

if [ "$#" -lt 1 ]; then
  printf 'You must supply the name of the NixOS config you want to install as an argument.\n\n'
  printf 'If the NixOS config you want to use is called example, then type:\n\n'
  printf '  install_script example\n' >&2
  exit 1
fi

DISKS=$(lsblk --nodeps --noheadings --include 8,259 --output NAME)
DISK_COUNT=$(printf '%s\n' "$DISKS" | wc -l)

case "$DISK_COUNT" in
  0)
    printf 'Cannot find a disk to install to, specify which disk to install to by supplying the'
    printf ' second argument:\n'
    printf '  install_script example /dev/sda\n'
    exit 1
    ;;
  1)
    echo "Wiping disk to prepare for installation: /dev/$DISKS"
    wipefs --all "/dev/$DISKS"
    ;;
  *)
    printf 'Multiple disks detected:\n'
    printf '%s\n' "$disks"
    printf '\n\nRerun this command with two arguments, the first specifying the NixOS config name '
    printf 'and the second one specifying the target disk to install to:\n'
    printf '  install_script example /dev/sda\n'
    exit 1
    ;;
esac

# Apply the disko config to the disks
disko --mode disko "./modules/hosts/$1/_disko.nix"

# Copy the repository to /mnt and cd into it:
cp -r ../nix-config /mnt/nix-config && cd /mnt/nix-config

# Install NixOS
nixos-install --no-root-password --flake ".#$1"

printf '\n\nInstallation completed, take your USB stick out and restart.'
