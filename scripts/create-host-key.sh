#!/usr/bin/env bash
set -euo pipefail

if [ -z "${SOPS_AGE_KEY:-}" ]; then
  printf 'SOPS_AGE_KEY is not set. Re-run with:\n  SOPS_AGE_KEY="AGE-SECRET-KEY-..." create-host-key\n' >&2
  exit 1
fi

read -r -p "Hostname: " NAME_OF_HOST
if [ -z "$NAME_OF_HOST" ]; then
  printf 'Hostname cannot be empty.\n' >&2
  exit 1
fi

if [ -f "secrets/host_keys/$NAME_OF_HOST.yml" ]; then
  printf 'secrets/host_keys/%s.yml already exists.\n' "$NAME_OF_HOST" >&2
  exit 1
fi

if [ -f ./id_ed25519 ] && [ -f ./id_ed25519.pub ]; then
  printf 'Warning: keypair already exists at ./id_ed25519.\n' >&2
  exit 1
else
  ssh-keygen -t ed25519 -N "" -f ./id_ed25519 > /dev/null 2>&1
fi

printf 'NOTE: Add this to .sops.yaml: %s\n' "$(ssh-to-age < ./id_ed25519.pub)"

if [ -f "secrets/host_keys/$NAME_OF_HOST.yml" ]; then
  printf 'secrets/host_keys/%s.yml already exists.\n' "$NAME_OF_HOST" >&2
  exit 1
fi

target="secrets/host_keys/$NAME_OF_HOST.yml"
printf 'id_ed25519: |\n%s\nid_ed25519_pub: %s\n' \
  "$(sed 's/^/  /' ./id_ed25519)" \
  "$(cat ./id_ed25519.pub)" \
  > "$target"
sops --encrypt --in-place --input-type yaml --output-type yaml "$target"
rm ./id_ed25519 ./id_ed25519.pub
