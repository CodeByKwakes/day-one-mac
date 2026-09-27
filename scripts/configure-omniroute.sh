#!/usr/bin/env bash
# Digest-pinned, local-only gateway lifecycle. Never adopt or delete resources.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/project-paths.sh"
source "$SCRIPT_DIR/lib/module-execution.sh"
ORIGINAL_ARGS=("$@")
STATE_ROOT="$(day_one_state_root)"
STATE_DIR="$(day_one_state_dir "$STATE_ROOT")"
ACTION='' INPUT='' YES=0 CONTEXT='' IMAGE='' PORT='' SELECTION=''
NAME=omniroute VOLUME=omniroute-data OWNER=module-10a-v1
SAVED="$STATE_DIR/omniroute-selection.tsv"
HAVE_CONTAINER=0 HAVE_VOLUME=0
die() { printf '%s\n' "$1" >&2; exit "${2:-1}"; }
usage() {
  cat <<'EOF'
Usage: configure-omniroute.sh --plan|--apply|--check|--resume [--manifest PATH] [--yes]
Manifest: context<TAB>orbstack, image<TAB>diegosouzapw/omniroute@sha256:<64 hex>,
port<TAB>1024..65535. No credentials. Apply requires Phase 8 and local OrbStack.
Plan prints the proposal only; apply/check inspect ownership and exact spec.
Creates only omniroute and omniroute-data; never adopts, replaces or deletes.
Provider credentials, accounts, billing, dashboard setup and client routing are manual.
EOF
}
while (( $# )); do
  case "$1" in
    --plan|--apply|--check|--resume) [[ -z "$ACTION" ]] || die 'Choose one action.' 2; ACTION="${1#--}"; shift ;;
    --manifest) [[ $# -ge 2 && -z "$INPUT" && -n "$2" ]] || die 'Manifest needs one path.' 2; INPUT="$2"; shift 2 ;;
    --yes) YES=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die 'Unknown OmniRoute option.' 2 ;;
  esac
done
[[ -n "$ACTION" ]] || die 'Choose one action.' 2
[[ "$ACTION" != resume || -z "$INPUT" ]] || die 'Resume uses saved choices.' 2
[[ "$YES" == 0 || "$ACTION" == apply || "$ACTION" == resume ]] || die '--yes is apply/resume only.' 2
if [[ "$ACTION" == apply || "$ACTION" == resume ]]; then
  day_one_serialize omniroute "$0" "${ORIGINAL_ARGS[@]}"
  [[ -s "$STATE_DIR/completed/08" ]] || die 'Complete required Phase 8 first; planning is available.' 10
fi
safe_path() {
  local path="$1"
  while [[ "$path" != / && "$path" != . ]]; do
    [[ ! -L "$path" ]] || return 1
    path="$(dirname "$path")"
  done
}
safe_path "$STATE_DIR" || die 'Unsafe state directory.'
INPUT="${INPUT:-$SAVED}"
[[ -f "$INPUT" && -r "$INPUT" ]] && safe_path "$INPUT" || die 'Provide a reviewed OmniRoute manifest.' 2
while IFS= read -r row || [[ -n "$row" ]]; do
  [[ -n "$row" && "$row" != \#* ]] || continue
  [[ "$row" == *$'\t'* && "$row" != *$'\r'* ]] || die 'Expected key and value separated by one tab.' 2
  key="${row%%$'\t'*}"; value="${row#*$'\t'}"
  [[ -n "$value" && "$value" != *$'\t'* ]] || die 'Expected exactly two nonempty fields.' 2
  case "$key" in
    context) [[ -z "$CONTEXT" && "$value" == orbstack ]] || die 'Only explicit local orbstack context is supported.' 2; CONTEXT="$value" ;;
    image) [[ -z "$IMAGE" && "$value" =~ ^diegosouzapw/omniroute@sha256:[a-f0-9]{64}$ ]] || die 'Use one reviewed OmniRoute sha256 image digest, never a tag.' 2; IMAGE="$value" ;;
    port) [[ -z "$PORT" && "$value" =~ ^[1-9][0-9]{3,4}$ ]] && (( value >= 1024 && value <= 65535 )) || die 'Use one port from 1024 through 65535.' 2; PORT="$value" ;;
    *) die 'Unsupported OmniRoute manifest key.' 2 ;;
  esac
done < "$INPUT"
[[ -n "$CONTEXT" && -n "$IMAGE" && -n "$PORT" ]] || die 'Manifest needs context, image and port.' 2
SELECTION="$(printf 'context\t%s\nimage\t%s\nport\t%s' "$CONTEXT" "$IMAGE" "$PORT")"
SPEC="$(printf '%s\n%s\n' "$OWNER" "$SELECTION" | shasum -a 256 | awk '{print $1}')"
printf 'Scope: local container health only. Provider keys, billing, dashboard and client routing remain manual.\n'
if [[ "$ACTION" == plan ]]; then
  printf 'Plan only; Docker availability, collisions and image healthcheck are validated on apply.\n%s\n' "$SELECTION"
  printf 'Create owned %s + volume %s, bind 127.0.0.1:%s:20128, limit memory to 10 GiB (runtime 8192 MiB).\n' "$NAME" "$VOLUME" "$PORT"
  printf 'Require API keys; no credentials are generated or forwarded. Preserve existing resources; refuse unowned names.\n'
  [[ -s "$STATE_DIR/completed/08" ]] || printf 'Blocked on apply: complete Phase 8.\n'
  exit 0
fi
[[ ! -d "$HOME/.orbstack/bin" ]] || export PATH="$PATH:$HOME/.orbstack/bin"
command -v docker >/dev/null 2>&1 || die 'Docker CLI unavailable. Install/start OrbStack manually.' 10
endpoint="$(docker context inspect --format '{{.Endpoints.docker.Host}}' "$CONTEXT")" || die 'Cannot inspect Docker context.'
[[ "$endpoint" == unix:///* && "$endpoint" != *$'\n'* ]] || die 'Refusing a non-local Docker context.'
dock() { docker --context "$CONTEXT" "$@"; }
dock info --format '{{.ServerVersion}}' >/dev/null || die 'Local Docker engine unavailable.' 10
containers="$(dock container ls -a --format '{{.Names}}')" || die 'Cannot inventory containers.'
volumes="$(dock volume ls --format '{{.Name}}')" || die 'Cannot inventory volumes.'
if grep -Fxq "$NAME" <<< "$containers"; then HAVE_CONTAINER=1; fi
if grep -Fxq "$VOLUME" <<< "$volumes"; then HAVE_VOLUME=1; fi
inspect() { dock container inspect --format "$1" "$NAME"; }
image_field() { dock image inspect --format "$1" "$IMAGE"; }
expect() {
  local actual
  actual="$(inspect "$1")" || die 'Container inspection failed.'
  [[ "$actual" == "$2" ]] || die 'Existing container differs from reviewed specification; manual review required. Nothing replaced.'
}
verify_volume() {
  local value users
  value="$(dock volume inspect --format '{{index .Labels "com.day-one-mac.owner"}}|{{.Driver}}|{{.Scope}}|{{len .Options}}' "$VOLUME")" || die 'Volume inspection failed.'
  [[ "$value" == "$OWNER|local|local|0" ]] || die 'Refusing an unowned or nonstandard volume.'
  users="$(dock container ls -a --filter "volume=$VOLUME" --format '{{.Names}}')" || die 'Cannot inspect volume users.'
  [[ -z "$users" || "$users" == "$NAME" ]] || die 'Volume is shared with other containers; review manually.'
}
verify_image() {
  local health
  IMAGE_ID="$(image_field '{{.Id}}')" || die 'Pinned image is not available locally.'
  [[ "$IMAGE_ID" == sha256:* ]] || die 'Cannot resolve pinned image identity.'
  health="$(image_field '{{if .Config.Healthcheck}}{{json .Config.Healthcheck.Test}}{{end}}')" || die 'Cannot inspect image healthcheck.'
  [[ -n "$health" && "$health" != null && "$health" != '[]' && "$health" != '["NONE"]' ]] || die 'Reviewed image needs a built-in healthcheck.'
}
verify_container() {
  local field image_value expected_env actual_env
  verify_image
  expect '{{index .Config.Labels "com.day-one-mac.owner"}}|{{index .Config.Labels "com.day-one-mac.spec"}}' "$OWNER|$SPEC"
  expect '{{.Config.Image}}|{{.Image}}' "$IMAGE|$IMAGE_ID"
  expect '{{len .HostConfig.PortBindings}}|{{range (index .HostConfig.PortBindings "20128/tcp")}}{{.HostIp}}:{{.HostPort}}{{end}}|{{len (index .HostConfig.PortBindings "20128/tcp")}}' "1|127.0.0.1:$PORT|1"
  expect '{{.HostConfig.PublishAllPorts}}|{{.HostConfig.AutoRemove}}|{{len .HostConfig.VolumesFrom}}' 'false|false|0'
  expect '{{len .Mounts}}|{{range .Mounts}}{{.Type}}|{{.Name}}|{{.Destination}}|{{.RW}}{{end}}' "1|volume|$VOLUME|/app/data|true"
  expect '{{.HostConfig.NetworkMode}}|{{len .NetworkSettings.Networks}}|{{range $key, $value := .NetworkSettings.Networks}}{{$key}}{{end}}' 'bridge|1|bridge'
  expect '{{.HostConfig.Privileged}}|{{.HostConfig.PidMode}}|{{len .HostConfig.Devices}}|{{len .HostConfig.CapAdd}}|{{json .HostConfig.SecurityOpt}}' 'false||0|0|["no-new-privileges"]'
  expect '{{.HostConfig.Memory}}|{{.HostConfig.RestartPolicy.Name}}|{{.Config.StopTimeout}}' '10737418240|unless-stopped|40'
  for field in Entrypoint Cmd Healthcheck User WorkingDir; do
    image_value="$(image_field "{{json .Config.$field}}")" || die 'Image configuration inspection failed.'
    expect "{{json .Config.$field}}" "$image_value"
  done
  # JSON-encode each entry so embedded newlines cannot masquerade as extra vars.
  image_value="$(image_field '{{range .Config.Env}}{{println (json .)}}{{end}}')" || die 'Image environment inspection failed.'
  expected_env="$( { printf '%s\n' "$image_value" | sed '/^"OMNIROUTE_MEMORY_MB=/d; /^"REQUIRE_API_KEY=/d; /^$/d'; printf '"OMNIROUTE_MEMORY_MB=8192"\n"REQUIRE_API_KEY=true"\n'; } | LC_ALL=C sort)"
  actual_env="$(inspect '{{range .Config.Env}}{{println (json .)}}{{end}}')" || die 'Container environment inspection failed.'
  actual_env="$(printf '%s\n' "$actual_env" | sed '/^$/d' | LC_ALL=C sort)"
  [[ "$actual_env" == "$expected_env" ]] || die 'Container environment differs; review manually. Values were not printed.'
}
health_ok() { [[ "$(inspect '{{.State.Status}}|{{if .State.Health}}{{.State.Health.Status}}{{end}}')" == 'running|healthy' ]]; }
if [[ "$HAVE_VOLUME" == 1 ]]; then verify_volume; fi
if [[ "$HAVE_CONTAINER" == 1 ]]; then
  [[ "$HAVE_VOLUME" == 1 ]] || die 'Existing container has no expected volume.'
  verify_container
fi
if [[ "$ACTION" == check ]]; then
  [[ "$HAVE_CONTAINER" == 1 && "$HAVE_VOLUME" == 1 ]] && health_ok || die 'Owned gateway is missing or not healthy.'
  printf 'Owned digest-pinned gateway is healthy on loopback. Provider readiness is not verified.\n'
  exit 0
fi
if [[ "$YES" == 0 ]]; then
  [[ -t 0 ]] || die 'Apply needs terminal confirmation or --yes.' 10
  printf 'Create/start the reviewed local gateway, preserving all data? [y/N]: '
  IFS= read -r answer
  [[ "$answer" == y || "$answer" == Y || "$answer" == yes ]] || exit 10
fi
safe_path "$STATE_DIR/module-runs/10A" || die 'Unsafe run directory.'
day_one_module_begin 10A "$SELECTION" "$SAVED"
day_one_write_state "$SAVED" "$SELECTION"
if [[ "$HAVE_CONTAINER" == 0 ]]; then
  day_one_module_event pull "$IMAGE"
  dock pull "$IMAGE" || die 'Pull failed; saved selection can be resumed.'
  verify_image
  if [[ "$HAVE_VOLUME" == 0 ]]; then
    day_one_module_event create-volume "$VOLUME"
    dock volume create --label "com.day-one-mac.owner=$OWNER" "$VOLUME" >/dev/null
    verify_volume
  fi
  day_one_module_event create-container "$NAME"
  dock container create --name "$NAME" --label "com.day-one-mac.owner=$OWNER" \
    --label "com.day-one-mac.spec=$SPEC" --network bridge --security-opt no-new-privileges \
    --restart unless-stopped --stop-timeout 40 --memory 10g \
    -p "127.0.0.1:$PORT:20128" --mount "type=volume,src=$VOLUME,dst=/app/data" \
    -e OMNIROUTE_MEMORY_MB=8192 -e REQUIRE_API_KEY=true "$IMAGE" > "$MODULE_RUN/container-id"
  verify_container
fi
status="$(inspect '{{.State.Status}}')" || die 'Cannot read gateway state.'
case "$status" in
  running) ;;
  created|exited)
    day_one_module_event start "$NAME"
    dock container start "$NAME" >/dev/null ;;
  *) die 'Gateway has a transitional or unsupported state; inspect manually and resume.' ;;
esac
for (( attempt=0; attempt<30; attempt++ )); do
  if health_ok; then
    MODULE_VERIFIED=1
    printf 'Gateway healthy: http://127.0.0.1:%s (provider setup still manual).\n' "$PORT"
    exit 0
  fi
  sleep 2
done
die 'Gateway did not become healthy within 60 seconds. Resources retained; inspect Docker logs manually and resume.'
