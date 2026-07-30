#!/usr/bin/env bash
set -euo pipefail

if [ -f ./id_ed25519 ] && [ -f ./id_ed25519.pub ]; then
  printf 'Warning: keypair already exists at ./id_ed25519, skipping generation\n' >&2
else
  ssh-keygen -t ed25519 -N "" -f ./id_ed25519 > /dev/null 2>&1
fi
printf '%s\n' "$(ssh-to-age < ./id_ed25519.pub)"
