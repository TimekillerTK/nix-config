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
  printf '  install-os example\n' >&2
  exit 1
fi

DISKS=$(lsblk --nodeps --noheadings --include 8,259 --output NAME)
DISK_COUNT=$(printf '%s\n' "$DISKS" | wc -l)

case "$DISK_COUNT" in
  0)
    echo '------------------------------------------------------'
    printf 'Cannot find a disk to install to, specify which disk to install to by supplying the'
    printf ' second argument:\n'
    printf '  install-os example /dev/sda\n'
    exit 1
    ;;
  1)
    echo '------------------------------------------------------'
    printf 'Wiping disk to prepare for installation: /dev/%s\n' "$DISKS"
    wipefs --all "/dev/$DISKS"
    ;;
  *)
    echo '------------------------------------------------------'
    printf 'Multiple disks detected:\n'
    printf '%s\n' "$disks"
    printf '\n\nRerun this command with two arguments, the first specifying the NixOS config name '
    printf 'and the second one specifying the target disk to install to:\n'
    printf '  install-os example /dev/sda\n'
    exit 1
    ;;
esac

# Apply the disko config to the disks
echo '------------------------------------------------------'
printf 'Wiping, partitioning, formatting the disk & mounting partitions...\n'
disko --mode destroy,format,mount --yes-wipe-all-disks "./modules/hosts/$1/_disko.nix"
printf 'Done!\n'

# Copy the repository to /mnt:
echo '------------------------------------------------------'
printf 'Copying repository to install location...\n'
cp -r ../nix-config /mnt/nix-config
printf 'Done!\n'

# Sanity checks to see if we have what we need for installing the bootloader
echo '------------------------------------------------------'
printf 'Sanity checking everything before installation...\n'
mountpoint -q /mnt || { echo "ERROR: /mnt not mounted"; exit 1; }
mountpoint -q /mnt/boot || { echo "ERROR: /mnt/boot not mounted"; exit 1; }
[ -d "/sys/firmware/efi" ] || { echo "ERROR: Not in UEFI mode"; exit 1; }
printf 'Everything is OK!\n'

# Install NixOS - bootloader sometimes has issues with installation
# on the first try, so if it fails, wait a bit and rerun this command and try again
echo '------------------------------------------------------'
printf 'Installing Operating System NixOS flake "%s" ...\n' "$1"
nixos-install --no-root-password --flake ".#$1"

printf '\n\nInstallation completed, take your USB stick out and restart.\n'
