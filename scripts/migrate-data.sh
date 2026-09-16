#!/usr/bin/env bash
set -euo pipefail

# migrate-data: copy a docker-compose service's data volumes into an existing
# Incus instance's data volume, using the Nix config as the source of truth.
#
# The Incus target (instance name, data volume name/pool, mount path(s)) is
# derived from the `incusInstances` option in the NixOS configuration, so you
# only need to point it at the docker service to migrate FROM.
#
# Data is copied by mounting the data volume's backing ZFS dataset directly on
# the Incus host (the instance is stopped for the duration) and streaming a
# tarball of each bind mount into it. This avoids `incus file push`, which only
# writes into a stopped instance's root filesystem — not its mounted volumes.

usage() {
  cat >&2 <<'EOF'
Usage: migrate-data --service <name> [options]

Required:
  --service <name>       Docker compose service name (also the incusInstances key
                         unless --instance is given).

Options:
  --nixos-host <name>    Which nixosConfigurations to read (default: flooficus).
  --source-host <host>   SSH target for the docker host (default: dockerhost).
  --compose-file <path>  Path to docker-compose.yml on the source host
                         (default: /home/tk/docker/docker-compose.yml).
  --domain <suffix>      Domain appended to --nixos-host to reach the incus
                         machine (default: cyn.internal).
  --ssh-user <user>      SSH user for the incus machine (default: tk).
  --instance <name>      Incus instance name (default: <service>).
  --puid <uid>           Override ownership UID (container-relative; default:
                         parsed from compose).
  --pgid <gid>           Override ownership GID (container-relative; default:
                         parsed from compose).
  --skip-stop            Do not stop the docker container before copying.
  --start                Start the Incus instance when done.
  --dry-run              Print resolved commands without executing anything.
  -h, --help             Show this help.
EOF
  exit "${1:-0}"
}

# --- Argument parsing -------------------------------------------------------

SERVICE=""
NIXOS_HOST="flooficus"
SOURCE_HOST="dockerhost"
COMPOSE_FILE="/home/tk/docker/docker-compose.yml"
DOMAIN="cyn.internal"
SSH_USER="tk"
INSTANCE=""
PUID=""
PGID=""
SKIP_STOP=0
START=0
DRY_RUN=0

while [ $# -gt 0 ]; do
  case "$1" in
    --service)      SERVICE="$2"; shift 2 ;;
    --nixos-host)   NIXOS_HOST="$2"; shift 2 ;;
    --source-host)  SOURCE_HOST="$2"; shift 2 ;;
    --compose-file) COMPOSE_FILE="$2"; shift 2 ;;
    --domain)       DOMAIN="$2"; shift 2 ;;
    --ssh-user)     SSH_USER="$2"; shift 2 ;;
    --instance)     INSTANCE="$2"; shift 2 ;;
    --puid)         PUID="$2"; shift 2 ;;
    --pgid)         PGID="$2"; shift 2 ;;
    --skip-stop)    SKIP_STOP=1; shift ;;
    --start)        START=1; shift ;;
    --dry-run)      DRY_RUN=1; shift ;;
    -h|--help)      usage 0 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; usage 1 ;;
  esac
done

if [ -z "$SERVICE" ]; then
  printf 'Error: --service is required.\n\n' >&2
  usage 1
fi

INSTANCE="${INSTANCE:-$SERVICE}"

INCUS_FQDN="${NIXOS_HOST}.${DOMAIN}"
INCUS_SSH="${SSH_USER}@${INCUS_FQDN}"

# --- Helpers ----------------------------------------------------------------

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '  DRY-RUN: %s\n' "$*" >&2
  else
    "$@"
  fi
}

norm() {
  printf '%s' "$1" | sed 's:/\{1,\}$::'
}

# --- Step 1: discover the Incus target from the Nix config -----------------

printf 'Discovering Incus target from Nix config (%s)...\n' "$NIXOS_HOST"

NIX_QUERY='.#nixosConfigurations.'"$NIXOS_HOST"'.config.incusInstances'
if ! NIX_JSON=$(nix eval --json --impure "$NIX_QUERY"); then
  die "failed to evaluate $NIX_QUERY (run from the repo root inside the dev shell?)"
fi

CONFIG_YAML=$(printf '%s' "$NIX_JSON" | jq -r --arg i "$INSTANCE" '.[$i].configYaml // empty')
if [ -z "$CONFIG_YAML" ] || [ "$CONFIG_YAML" = "null" ]; then
  die "no incusInstances entry named '$INSTANCE' in $NIXOS_HOST"
fi

VOLUME=$(printf '%s' "$NIX_JSON" | jq -r --arg i "$INSTANCE" '.[$i].dataVolume.name // empty')
POOL=$(printf '%s' "$NIX_JSON" | jq -r --arg i "$INSTANCE" '.[$i].dataVolume.pool // empty')
if [ -z "$VOLUME" ] || [ "$VOLUME" = "null" ]; then
  die "instance '$INSTANCE' has no dataVolume; nothing to migrate into"
fi

printf '  instance=%s  volume=%s/%s\n' "$INSTANCE" "$POOL" "$VOLUME"

# --- Step 2: extract mount path(s) from the instance YAML -------------------

MOUNT_PATHS=()
while IFS= read -r p; do
  [ -n "$p" ] && MOUNT_PATHS+=("$p")
done < <(yq -o=json '.devices' "$CONFIG_YAML" \
           | jq -r --arg v "$VOLUME" 'to_entries[] | select(.value.source == $v) | .value.path')

if [ "${#MOUNT_PATHS[@]}" -eq 0 ]; then
  die "could not find a device in $CONFIG_YAML referencing volume '$VOLUME'"
fi

printf '  mount path(s): %s\n' "${MOUNT_PATHS[*]}"

# --- Step 3: parse the docker compose file (remote) -------------------------

printf 'Parsing docker compose for service "%s" on %s...\n' "$SERVICE" "$SOURCE_HOST"

COMPOSE_DIR="$(dirname "$COMPOSE_FILE")"
COMPOSE_BASE="$(basename "$COMPOSE_FILE")"
COMPOSE_CMD="cd '$COMPOSE_DIR' && docker compose -f '$COMPOSE_BASE' config --format json"

if ! COMPOSE_JSON=$(ssh "$SOURCE_HOST" "$COMPOSE_CMD"); then
  die "failed to read $COMPOSE_FILE on $SOURCE_HOST"
fi

COMPOSE_PUID=$(printf '%s' "$COMPOSE_JSON" | jq -r --arg s "$SERVICE" '.services[$s].environment.PUID // empty')
COMPOSE_PGID=$(printf '%s' "$COMPOSE_JSON" | jq -r --arg s "$SERVICE" '.services[$s].environment.PGID // empty')
PUID="${PUID:-${COMPOSE_PUID:-1000}}"
PGID="${PGID:-${COMPOSE_PGID:-1000}}"

printf '  ownership (container): %s:%s\n' "$PUID" "$PGID"

BINDS=()
while IFS=$'\t' read -r src tgt; do
  [ -z "$src" ] && continue

  case "$src" in
    /*|./*|../*|~*) : ;; # bind mount
    *) die "volume '$src' for service '$SERVICE' is a named docker volume, not a bind mount (not supported)" ;;
  esac

  if [ -z "$tgt" ]; then
    die "volume '$src' for service '$SERVICE' has no container target path"
  fi

  BINDS+=("$src"$'\t'"$tgt")
done < <(printf '%s' "$COMPOSE_JSON" | jq -r --arg s "$SERVICE" '
  .services[$s].volumes[]?
  | if type == "object"
    then [(.source // ""), (.target // "")]
    else (split(":") | [(.[0] // ""), (.[1] // "")])
    end
  | @tsv
')

if [ "${#BINDS[@]}" -eq 0 ]; then
  die "service '$SERVICE' has no bind-mounted volumes"
fi

printf '  bind mount(s):\n'
for b in "${BINDS[@]}"; do
  printf '    %s -> %s\n' "${b%%$'\t'*}" "${b#*$'\t'}"
done

# --- Step 4: stop the docker container --------------------------------------

if [ "$SKIP_STOP" -eq 1 ]; then
  printf 'Skipping docker stop (--skip-stop).\n'
else
  printf 'Stopping docker container %s...\n' "$SERVICE"
  run ssh "$SOURCE_HOST" "cd '$COMPOSE_DIR' && docker compose -f '$COMPOSE_BASE' stop '$SERVICE'"
fi

# --- Step 5: stop the Incus instance, mount its ZFS volume, transfer --------

printf 'Checking Incus instance %s on %s...\n' "$INSTANCE" "$INCUS_FQDN"
if ! INFO_OUT=$(ssh "$INCUS_SSH" "incus info '$INSTANCE'" 2>&1); then
  die "could not query incus instance '$INSTANCE' on $INCUS_FQDN: $INFO_OUT"
fi

if printf '%s\n' "$INFO_OUT" | grep -q 'Status: RUNNING'; then
  printf 'Stopping Incus instance %s...\n' "$INSTANCE"
  run ssh "$INCUS_SSH" "incus stop '$INSTANCE'"
fi

# Resolve the ZFS dataset backing the data volume. Custom volumes live at
# <pool-source>/custom/<project>_<volume>; match by volume name so we don't
# have to hardcode the project prefix.
POOL_SRC=$(ssh "$INCUS_SSH" "incus storage get '$POOL' source") \
  || die "cannot resolve ZFS source for pool '$POOL'"
DATASET=$(ssh "$INCUS_SSH" "zfs list -H -o name -t filesystem -r '$POOL_SRC'" \
  | awk -v v="$VOLUME" 'index($0,"/custom/") && substr($0,length($0)-length(v)+1)==v {print; exit}') \
  || die "cannot list ZFS datasets under '$POOL_SRC'"
if [ -z "$DATASET" ]; then
  die "no ZFS dataset found for volume '$VOLUME' in pool '$POOL'"
fi
printf '  zfs dataset: %s\n' "$DATASET"

# Incus unprivileged containers store on-disk ownership using host IDs. The
# active ID mapping lives in `volatile.idmap.current` (a JSON array of ranges);
# map each container-relative PUID/PGID through its range to the host ID.
IDMAP=$(ssh "$INCUS_SSH" "incus config get '$INSTANCE' volatile.idmap.current" 2>/dev/null || true)
[ -z "$IDMAP" ] && IDMAP=$(ssh "$INCUS_SSH" "incus config get '$INSTANCE' volatile.idmap.next" 2>/dev/null || true)

idmap_lookup() {
  # $1 = uid|gid, $2 = container ID -> prints host ID (empty if unmapped)
  local kind="$1" id="$2" flag
  [ "$kind" = uid ] && flag="Isuid" || flag="Isgid"
  printf '%s' "$IDMAP" | jq -r --argjson id "$id" --arg flag "$flag" \
    '.[] | select(.[$flag] == true) | select(.Nsid <= $id and $id < (.Nsid + .Maprange))
         | ($id + (.Hostid - .Nsid))' | head -n1
}

HOST_PUID=$(idmap_lookup uid "$PUID"); HOST_PUID="${HOST_PUID:-$PUID}"
HOST_PGID=$(idmap_lookup gid "$PGID"); HOST_PGID="${HOST_PGID:-$PGID}"
printf '  ownership (host): %s:%s\n' "$HOST_PUID" "$HOST_PGID"

MNT="/tmp/migrate-${SERVICE}"
cleanup() {
  run ssh "$INCUS_SSH" "sudo umount '$MNT' 2>/dev/null || true; sudo rmdir '$MNT' 2>/dev/null || true"
}
trap cleanup EXIT

printf 'Mounting %s at %s on %s...\n' "$DATASET" "$MNT" "$INCUS_FQDN"
run ssh "$INCUS_SSH" "sudo mkdir -p '$MNT' && sudo mount -t zfs '$DATASET' '$MNT'"

for b in "${BINDS[@]}"; do
  src="${b%%$'\t'*}"
  tgt="${b#*$'\t'}"

  ntgt="$(norm "$tgt")"

  mount_path=""
  subdir=""
  for p in "${MOUNT_PATHS[@]}"; do
    if [ "$(norm "$p")" = "$ntgt" ]; then
      mount_path="$(norm "$p")"
      break
    fi
  done

  if [ -z "$mount_path" ]; then
    if [ "${#MOUNT_PATHS[@]}" -eq 1 ]; then
      mount_path="$(norm "${MOUNT_PATHS[0]}")"
      subdir="$(basename "$src")"
    else
      die "bind '$src -> $tgt' matches no mount path and there are multiple (${MOUNT_PATHS[*]})"
    fi
  fi

  remote_target="$MNT"
  [ -n "$subdir" ] && remote_target="$remote_target/$subdir"

  printf 'Transferring %s -> %s:%s ...\n' "$src" "$INSTANCE" "$remote_target"

  run ssh "$INCUS_SSH" "sudo mkdir -p '$remote_target'"

  if [ "$DRY_RUN" -eq 1 ]; then
    printf '  DRY-RUN: ssh %s "tar czf - -C %s ." | pv -s <size> -p -t -e -r | ssh %s "sudo tar xzf - -C %s"\n' \
      "$SOURCE_HOST" "$src" "$INCUS_SSH" "$remote_target" >&2
  else
    if command -v pv >/dev/null 2>&1; then
      size="$(ssh "$SOURCE_HOST" "du -sb '$src'" 2>/dev/null | awk '{print $1}')"
      pv_args=(pv)
      [ -n "$size" ] && pv_args+=(-s "$size")
      pv_args+=(-p -t -e -r)
      ssh "$SOURCE_HOST" "tar czf - -C '$src' ." \
        | "${pv_args[@]}" \
        | ssh "$INCUS_SSH" "sudo tar xzf - -C '$remote_target'"
    else
      ssh "$SOURCE_HOST" "tar czf - -C '$src' ." \
        | ssh "$INCUS_SSH" "sudo tar xzf - -C '$remote_target'"
    fi
  fi

  run ssh "$INCUS_SSH" "sudo chown -R '$HOST_PUID:$HOST_PGID' '$remote_target'"
done

run ssh "$INCUS_SSH" "sudo umount '$MNT' && sudo rmdir '$MNT'"

# --- Step 6: optionally start the instance ----------------------------------

if [ "$START" -eq 1 ]; then
  printf 'Starting Incus instance %s...\n' "$INSTANCE"
  run ssh "$INCUS_SSH" "incus start '$INSTANCE'"
else
  printf 'Instance %s left stopped; start it manually to verify.\n' "$INSTANCE"
fi

printf 'Done.\n'
