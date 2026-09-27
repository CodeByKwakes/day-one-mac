#!/usr/bin/env bash
set -euo pipefail
exec </dev/null
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d /private/tmp/day-one-omniroute.XXXXXX)"
trap 'rm -rf "$TEST_ROOT"' EXIT
TEST_STATE="$TEST_ROOT/state"
MOCK_ROOT="$TEST_ROOT/engine"
export MOCK_ROOT
mkdir -p "$TEST_ROOT/bin" "$MOCK_ROOT"
cat > "$TEST_ROOT/bin/docker" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >> "$MOCK_ROOT/calls"
if [[ "$1" == context ]]; then
  [[ "$*" == 'context inspect --format {{.Endpoints.docker.Host}} orbstack' ]] || exit 98
  printf '%s\n' "${MOCK_ENDPOINT:-unix:///private/tmp/mock-docker.sock}"
  exit
fi
[[ "$1" == --context && "$2" == orbstack ]] || exit 98
shift 2
case "$1 $2" in
  'info --format') printf '1\n' ;;
  'container ls')
    [[ "${MOCK_INVENTORY_FAIL:-0}" == 0 ]] || exit 7
    if [[ "$*" == *--filter* ]]; then
      [[ "${MOCK_SHARED:-0}" == 0 ]] || printf 'other\n'
    fi
    [[ ! -f "$MOCK_ROOT/container" ]] || printf 'omniroute\n' ;;
  'volume ls') [[ ! -f "$MOCK_ROOT/volume" ]] || printf 'omniroute-data\n' ;;
  'volume inspect') printf '%s\n' "${MOCK_VOLUME:-module-10a-v1|local|local|0}" ;;
  'volume create') touch "$MOCK_ROOT/volume" ;;
  'pull '*)
    [[ "${MOCK_PULL_FAIL:-0}" == 0 ]] || exit 7
    printf '%s' "$2" > "$MOCK_ROOT/image" ;;
  'image inspect')
    [[ -f "$MOCK_ROOT/image" ]] || exit 1
    case "$4" in
      '{{.Id}}') printf 'sha256:fixture\n' ;;
      *Healthcheck.Test*) printf '["CMD","healthcheck"]\n' ;;
      '{{range .Config.Env}}{{println (json .)}}{{end}}') printf '"PATH=/usr/bin"\n' ;;
      *) printf 'null\n' ;;
    esac ;;
  'container create')
    [[ "${MOCK_CREATE_FAIL:-0}" == 0 ]] || exit 7
    for arg in "$@"; do
      case "$arg" in
        com.day-one-mac.spec=*) printf '%s' "${arg#*=}" > "$MOCK_ROOT/spec" ;;
      esac
    done
    touch "$MOCK_ROOT/container"
    printf created > "$MOCK_ROOT/status"
    printf 'fixture-container-id\n' ;;
  'container start')
    [[ "${MOCK_START_FAIL:-0}" == 0 ]] || exit 7
    printf running > "$MOCK_ROOT/status" ;;
  'container inspect')
    format="$4"
    if [[ -n "${MOCK_BAD_FIELD:-}" && "$format" == *"$MOCK_BAD_FIELD"* ]]; then printf tampered; exit; fi
    case "$format" in
      *com.day-one-mac.owner*) printf 'module-10a-v1|%s\n' "$(cat "$MOCK_ROOT/spec")" ;;
      '{{.Config.Image}}|{{.Image}}') printf '%s|sha256:fixture\n' "$(cat "$MOCK_ROOT/image")" ;;
      *PortBindings*) printf '1|127.0.0.1:20128|1\n' ;;
      *PublishAllPorts*) printf 'false|false|0\n' ;;
      *Mounts*) printf '1|volume|omniroute-data|/app/data|true\n' ;;
      *NetworkMode*) printf 'bridge|1|bridge\n' ;;
      *Privileged*) printf 'false||0|0|["no-new-privileges"]\n' ;;
      *HostConfig.Memory*) printf '10737418240|unless-stopped|40\n' ;;
      '{{range .Config.Env}}{{println (json .)}}{{end}}')
        if [[ "${MOCK_ENV_NEWLINE:-0}" == 1 ]]; then
          printf '"PATH=/usr/bin\\nOMNIROUTE_MEMORY_MB=8192\\nREQUIRE_API_KEY=true"\n'
        else printf '"PATH=/usr/bin"\n"OMNIROUTE_MEMORY_MB=8192"\n"REQUIRE_API_KEY=true"\n'; fi ;;
      '{{.State.Status}}') cat "$MOCK_ROOT/status" ;;
      *State.Health*) printf '%s|%s\n' "$(cat "$MOCK_ROOT/status")" "${MOCK_HEALTH:-healthy}" ;;
      *) printf 'null\n' ;;
    esac ;;
  *) printf 'Unexpected docker request\n' >&2; exit 99 ;;
esac
MOCK
cat > "$TEST_ROOT/bin/sleep" <<'MOCK'
#!/usr/bin/env bash
exit 0
MOCK
chmod +x "$TEST_ROOT/bin/"*
run() {
  env PATH="$TEST_ROOT/bin:/usr/bin:/bin" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE" \
    DAY_ONE_MAC_STATE_DIR="$TEST_STATE" "$SCRIPT_DIR/day-one-mac" optional --module 10A "$@"
}
fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
expect_failure() {
  local expected="$1" actual=0
  shift
  "$@" > "$TEST_ROOT/error" 2>&1 || actual=$?
  [[ "$actual" == "$expected" ]] || { cat "$TEST_ROOT/error"; fail "expected $expected got $actual"; }
}
printf 'context\torbstack\nimage\tdiegosouzapw/omniroute@sha256:%064d\nport\t20128\n' 0 > "$TEST_ROOT/gateway.tsv"
run --plan --manifest "$TEST_ROOT/gateway.tsv" > "$TEST_ROOT/plan"
[[ ! -e "$TEST_STATE" && ! -e "$MOCK_ROOT/calls" ]] || fail 'plan touched state or Docker'
expect_failure 10 run --apply --manifest "$TEST_ROOT/gateway.tsv" --yes
mkdir -p "$TEST_STATE/completed"
printf fixture > "$TEST_STATE/completed/08"
MOCK_ENDPOINT=tcp://remote:2375 expect_failure 1 run --apply --manifest "$TEST_ROOT/gateway.tsv" --yes
MOCK_INVENTORY_FAIL=1 expect_failure 1 run --apply --manifest "$TEST_ROOT/gateway.tsv" --yes
touch "$MOCK_ROOT/volume"
MOCK_VOLUME='foreign|local|local|0' expect_failure 1 run --apply --manifest "$TEST_ROOT/gateway.tsv" --yes
rm "$MOCK_ROOT/volume"
MOCK_PULL_FAIL=1 expect_failure 1 run --apply --manifest "$TEST_ROOT/gateway.tsv" --yes
[[ -s "$TEST_STATE/omniroute-selection.tsv" ]] || fail 'failed apply lost saved choices'
MOCK_CREATE_FAIL=1 expect_failure 7 run --resume --yes
[[ -f "$MOCK_ROOT/volume" && ! -f "$MOCK_ROOT/container" ]] || fail 'partial volume not retained'
MOCK_START_FAIL=1 expect_failure 7 run --resume --yes
[[ -f "$MOCK_ROOT/container" ]] || fail 'created container not retained'
run --resume --yes > "$TEST_ROOT/resume"
run --check > "$TEST_ROOT/check"
env PATH="$TEST_ROOT/bin:/usr/bin:/bin" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE" \
  DAY_ONE_MAC_STATE_DIR="$TEST_STATE" "$SCRIPT_DIR/optional-status.sh" > "$TEST_ROOT/dashboard"
grep -Eq 'partial +10A —' "$TEST_ROOT/dashboard" || fail 'gateway falsely complete or not selected'
pulls="$(grep -c '^--context orbstack pull ' "$MOCK_ROOT/calls")"
run --resume --yes > "$TEST_ROOT/idempotent"
[[ "$pulls" == "$(grep -c '^--context orbstack pull ' "$MOCK_ROOT/calls")" ]] || fail 'resume pulled existing container image'
for field in com.day-one-mac.owner PortBindings PublishAllPorts Mounts NetworkMode Privileged HostConfig.Memory Entrypoint Cmd Healthcheck User WorkingDir Config.Env; do
  MOCK_BAD_FIELD="$field" expect_failure 1 run --check
  MOCK_BAD_FIELD="$field" expect_failure 1 run --resume --yes
done
MOCK_ENV_NEWLINE=1 expect_failure 1 run --check
MOCK_ENV_NEWLINE=1 expect_failure 1 run --resume --yes
MOCK_SHARED=1 expect_failure 1 run --check
MOCK_HEALTH=unhealthy expect_failure 1 run --check
MOCK_HEALTH=unhealthy expect_failure 1 run --resume --yes
run --resume --yes > "$TEST_ROOT/recovered"
before="$(find "$TEST_STATE" -type f -exec shasum -a 256 {} + | sort)"
run --check > "$TEST_ROOT/final-check"
[[ "$before" == "$(find "$TEST_STATE" -type f -exec shasum -a 256 {} + | sort)" ]] || fail 'check changed state'
if grep -Eq '(^| )(rm|remove|exec|context use|prune)( |$)' "$MOCK_ROOT/calls"; then fail 'destructive or context-changing Docker call'; fi
printf 'context\torbstack\nimage\tdiegosouzapw/omniroute:latest\nport\t20128\n' > "$TEST_ROOT/invalid.tsv"
expect_failure 2 run --plan --manifest "$TEST_ROOT/invalid.tsv"
[[ ! -e "$TEST_STATE.operation.lock" ]] || fail 'lock leaked'
printf 'PASS: pinned gateway, explicit local context, ownership/spec refusal, partial failure and resume\n'
