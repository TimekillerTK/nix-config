#!/bin/sh

# NOTE: Source for this is https://nix.dev/manual/nix/2.33/advanced-topics/post-build-hook.html

set -eu
set -f # disable globbing
export IFS=' '

# We need to sign whatever we are building with a key our nix binary cache trusts, in
# my case it's harmonia's secret
echo "Signing paths" "$OUT_PATHS"
nix store sign --key-file /var/lib/secrets/harmonia.secret "$OUT_PATHS"

# NOTE: Using the ssh key of my user since it already is configured, but should ideally
# be it's own dedicated ssh key and user with limited permissions
#
# TODO add condition to check:
#    ping -c 1 host.nix-cache.cyn.internal > /dev/null 2&>1
#
echo "Uploading paths" "$OUT_PATHS"
exec nix copy --to "ssh-ng://tk@host.nix-cache.cyn.internal?ssh-key=/home/tk/.ssh/id_ed25519" "$OUT_PATHS"
