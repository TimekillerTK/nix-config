#!/usr/bin/env bash
set -euo pipefail

if [ -z "${SOPS_AGE_KEY:-}" ]; then
  printf 'SOPS_AGE_KEY is not set. Re-run with:\n  SOPS_AGE_KEY="AGE-SECRET-KEY-..." create-host-key\n' >&2
  exit 1
fi

read -r -p "Hostname: " HOSTNAME
if [ -z "$HOSTNAME" ]; then
  printf 'Hostname cannot be empty.\n' >&2
  exit 1
fi

if [ ! -f ./id_ed25519 ] || [ ! -f ./id_ed25519.pub ]; then
  printf 'Keypair not found in current directory. Run ssh-to-age-key first.\n' >&2
  exit 1
fi

if [ -f "secrets/host_keys/$HOSTNAME.yml" ]; then
  printf 'secrets/host_keys/%s.yml already exists.\n' "$HOSTNAME" >&2
  exit 1
fi

target="secrets/host_keys/$HOSTNAME.yml"
printf 'id_ed25519: |\n%s\nid_ed25519_pub: %s\n' \
  "$(sed 's/^/  /' ./id_ed25519)" \
  "$(cat ./id_ed25519.pub)" \
  > "$target"
sops --encrypt --in-place --input-type yaml --output-type yaml "$target"
rm ./id_ed25519 ./id_ed25519.pub
