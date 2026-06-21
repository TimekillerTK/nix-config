#!/usr/bin/env bash
set -uo pipefail

# NOTE: Hostnames are injected by Nix at build time via string interpolation.
# into the HOSTS variable. Generated from builtins.attrNames
# inputs.self.nixosConfigurations in modules/features/systems.nix.
HOSTS=(@hosts@)

failed=()
passed=()
declare -A failed_output

echo "Checking all nixosConfigurations..."
echo ""
echo "Hosts: ${HOSTS[@]}"
echo "------------------------------------------------------"
echo ""

for host in "${HOSTS[@]}"; do
  printf '  [....] %s' "$host"
  output=$(NIXPKGS_ALLOW_UNFREE=1 nix eval ".#nixosConfigurations.${host}.config.system.build.toplevel" --impure 2>&1)
  if [ $? -eq 0 ]; then
    printf '\r  [ OK ] %s\n' "$host"
    passed+=("$host")
  else
    printf '\r  [FAIL] %s\n' "$host"
    failed+=("$host")
    failed_output["$host"]="$output"
  fi
done

echo ""
echo "------------------------------------------------------"
echo "Results: ${#passed[@]} passed, ${#failed[@]} failed"

if [ ${#failed[@]} -gt 0 ]; then
  echo ""
  echo "Failed hosts:"
  for host in "${failed[@]}"; do
    echo ""
    echo "  -- $host --"
    echo "${failed_output[$host]}"
  done
  exit 1
fi
