#!/bin/sh

set -eu
set -f # disable globbing
export IFS=' '

echo "Signing paths" $OUT_PATHS
exec nix store sign --key-file /home/tk/DELETE_ME $OUT_PATHS

echo "Uploading paths" $OUT_PATHS
exec nix copy --to "ssh-ng://tk@host.nix-cache.cyn.internal?ssh-key=/home/tk/.ssh/id_ed25519" $OUT_PATHS
