#!/bin/sh

# NOTE: Source for this is https://nix.dev/manual/nix/2.33/advanced-topics/post-build-hook.html
#
# NOTE: To skip this build hook during a nixos rebuld, an option can be passed with the
# rebuild command:
#
#    sudo nixos-rebuild switch --flake .# --option post-build-hook ""
#
set -eu
set -f # disable globbing
export IFS=' '

CACHE_HOST="host.nix-cache.cyn.internal"

# We need to sign whatever we are building with a key our nix binary cache trusts, in
# my case it's harmonia's secret
echo "Signing paths" "$OUT_PATHS"
nix store sign --key-file /var/lib/secrets/harmonia.secret "$OUT_PATHS"

# NOTE: Using the ssh key of my user since it already is configured, but should ideally
# be it's own dedicated ssh key and user with limited permissions
#
if ping -c 1 $CACHE_HOST > /dev/null 2>&1; then
  echo "Uploading paths" "$OUT_PATHS"
  exec nix copy --to "ssh-ng://tk@$CACHE_HOST?ssh-key=/home/tk/.ssh/id_ed25519" "$OUT_PATHS"
else
  echo "Ping to $CACHE_HOST failed, skipping upload." >&2
fi
