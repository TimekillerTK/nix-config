#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
  printf 'You must supply the name of the NixOS config you want to install as an argument.\n\n'
  printf 'If the NixOS config you want to use is called example, then type:\n\n'
  printf '  sudo install-os example\n' >&2
  exit 1
fi

# To install a host, we need the SOPS_AGE_KEY to be set to the
# 'master password' so that we can set the host key for the host
# in the last step to ensure everything works correctly with the
# way we use SOPS
if [ -z "${SOPS_AGE_KEY:-}" ]; then
  printf 'The environment variable SOPS_AGE_KEY must be first set to proceed '
  printf 'with installation.\n\n'
  printf 'To set, run this command again with SOPS_AGE_KEY="<agekeypasswordhere>":\n'
  printf '  sudo SOPS_AGE_KEY="AGE-SECRET-KEY-123ABCXYZ" install-os example\n\n'
  printf 'NOTE: The SOPS_AGE_KEY is in bitwarden.\n'
  exit 1
fi

# Set environment variables first, checking if we can set them or not,
# if the SOPS_AGE_KEY is invalid, it's pointless to continue, so error here
echo '------------------------------------------------------'
printf 'Acquiring PRIVATE/PUBLIC host keys for host "%s" from SOPS...\n' "$1"
PRIVATE_HOST_KEY=$(sops --decrypt --extract '["id_ed25519"]' "secrets/host_keys/$1.yml")
PUBLIC_HOST_KEY=$(sops --decrypt --extract '["id_ed25519_pub"]' "secrets/host_keys/$1.yml")
printf 'Done!\n'

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

DISKS=$(lsblk --nodeps --noheadings --include 8,259 --output NAME)
DISK_COUNT=$(printf '%s\n' "$DISKS" | wc -l)

# FIXME: For ease of use, add a section which lists the valid disk options available
# and how they can be used
#
# FIXME: Unbound variable error on $disks, supply multiple disks to reproduce
# (this actually happens when installing via USB because you have the USB disk and
# the disk you're installing on)
case "$DISK_COUNT" in
  0)
    echo '------------------------------------------------------'
    printf 'Cannot find a disk to install to, specify which disk to install to by supplying the'
    printf ' second argument:\n'
    printf '  sudo install-os example /dev/sda\n'
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
    printf '%s\n' "$DISKS"
    printf '\n\nRerun this command with two arguments, the first specifying the NixOS config name '
    printf 'and the second one specifying the target disk to install to:\n'
    printf '  sudo install-os example /dev/sda\n'
    exit 1
    ;;
esac

# If the host's disko config uses ZFS, verify the ZFS kernel module is loaded
if grep -qE 'zfs|zpool' "modules/hosts/$1/_disko.nix" 2>/dev/null; then
  if ! lsmod | grep -q zfs; then
    echo '------------------------------------------------------'
    printf 'ERROR: The host "%s" requires ZFS but the ZFS kernel module is not loaded.\n\n' "$1"
    printf 'The NixOS live ISO does not include ZFS by default. You have two options:\n\n'
    printf '  1. Use a NixOS installer ISO with an LTS kernel, which includes ZFS support.\n'
    printf '     Download the LTS ISO from: https://nixos.org/download\n\n'
    printf '  2. Load the ZFS module manually on the current ISO:\n'
    printf '     modprobe zfs\n\n'
    printf 'Aborting installation.\n'
    exit 1
  fi
fi

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

# Lastly, set the ssh host keys for the host
echo '------------------------------------------------------'
printf 'Setting the host keys for this host...\n' "$1"
echo "$PRIVATE_HOST_KEY" > /mnt/etc/ssh/ssh_host_ed25519_key
echo "$PUBLIC_HOST_KEY" > /mnt/etc/ssh/ssh_host_ed25519_key.pub
chmod 600 /mnt/etc/ssh/ssh_host_ed25519_key
chmod 644 /mnt/etc/ssh/ssh_host_ed25519_key.pub
printf 'Done!\n'

# Display warning
printf '\nNOTE: Installing Operating System might have failed on the secrets '
printf 'step - this is OK. Restart and reapply the config and the secrets will'
printf 'be decrypted.\n'
