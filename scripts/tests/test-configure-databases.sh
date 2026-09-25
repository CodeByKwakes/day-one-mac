#!/usr/bin/env bash
set -euo pipefail
exec </dev/null

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d /tmp/day-one-databases-test.XXXXXX)"
trap 'rm -rf "$TEST_ROOT"' EXIT HUP INT TERM
TEST_HOME="$TEST_ROOT/home"
TEST_STATE="$TEST_HOME/.day-one-mac"
MOCK_BIN="$TEST_ROOT/bin"
MOCK_STATE="$TEST_ROOT/docker-state"
MOCK_LOG="$TEST_ROOT/docker.log"
mkdir -p "$TEST_STATE/completed" "$MOCK_BIN" "$MOCK_STATE"
printf 'complete\n' > "$TEST_STATE/completed/08"

cat > "$MOCK_BIN/docker" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >> "$MOCK_DOCKER_LOG"
case "${1:-}" in
  info)
    [[ "${MOCK_DOCKER_INFO_FAIL:-0}" != 1 ]]
    ;;
  context) [[ "$2" == show ]]; printf 'fixture-context\n' ;;
  network)
    if [[ "$2" == inspect ]]; then [[ -f "$MOCK_DOCKER_STATE/network-$3" ]]
    else touch "$MOCK_DOCKER_STATE/network-$3"; printf '%s\n' "$3"; fi
    ;;
  volume)
    if [[ "$2" == inspect ]]; then [[ -f "$MOCK_DOCKER_STATE/volume-$3" ]]
    else touch "$MOCK_DOCKER_STATE/volume-$3"; printf '%s\n' "$3"; fi
    ;;
  container) [[ "$2" == inspect && -f "$MOCK_DOCKER_STATE/container-$3" ]] ;;
  inspect)
    name="${!#}"
    [[ -f "$MOCK_DOCKER_STATE/container-$name" ]] || exit 1
    if [[ "$2" == *State.Running* && "$2" != *State.Health* ]]; then printf 'true\n'; else printf 'healthy\n'; fi
    ;;
  run)
    [[ "$2" == -d ]]
    name=''
    while (( $# )); do
      if [[ "$1" == --name ]]; then name="$2"; break; fi
      shift
    done
    [[ -n "$name" ]]
    touch "$MOCK_DOCKER_STATE/container-$name"
    printf 'fixture-id\n'
    ;;
  start)
    touch "$MOCK_DOCKER_STATE/container-$2"
    printf '%s\n' "$2"
    ;;
  logs) : ;;
  *) printf 'unexpected docker command: %s\n' "$*" >&2; exit 2 ;;
esac
EOF
chmod +x "$MOCK_BIN/docker"

run_databases() {
  HOME="$TEST_HOME" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE" \
    MOCK_DOCKER_STATE="$MOCK_STATE" MOCK_DOCKER_LOG="$MOCK_LOG" \
    PATH="$MOCK_BIN:/usr/bin:/bin:/usr/sbin:/sbin" \
    "$SCRIPT_DIR/configure-databases.sh" "$@"
}

run_databases --services postgres,redis --yes > "$TEST_ROOT/install.txt"
grep -Fq 'database setup completed' "$TEST_ROOT/install.txt"
grep -Fqx 'postgres,redis' "$TEST_STATE/database-services"
[[ -s "$TEST_STATE/optional-completed/databases" ]]
[[ -s "$TEST_STATE/database-status.md" ]]
[[ -f "$MOCK_STATE/container-dev-postgres" ]]
[[ -f "$MOCK_STATE/container-dev-redis" ]]
grep -Fq -- '--name dev-postgres' "$MOCK_LOG"
grep -Fq -- '--name dev-redis' "$MOCK_LOG"

run_databases --saved --check > "$TEST_ROOT/check.txt"
grep -Fq 'postgres — healthy' "$TEST_ROOT/check.txt"
grep -Fq 'redis — healthy' "$TEST_ROOT/check.txt"

before_runs="$(grep -c '^run -d' "$MOCK_LOG")"
run_databases --saved --yes > "$TEST_ROOT/resume.txt"
after_runs="$(grep -c '^run -d' "$MOCK_LOG")"
[[ "$before_runs" == "$after_runs" ]]
grep -Fq 'already exists and is running' "$TEST_ROOT/resume.txt"

dry_state="$TEST_ROOT/dry-state"
mkdir -p "$dry_state/completed"
printf 'complete\n' > "$dry_state/completed/08"
HOME="$TEST_HOME" DAY_ONE_MAC_STATE_ROOT="$dry_state" \
  MOCK_DOCKER_STATE="$MOCK_STATE" MOCK_DOCKER_LOG="$MOCK_LOG" \
  PATH="$MOCK_BIN:/usr/bin:/bin:/usr/sbin:/sbin" \
  "$SCRIPT_DIR/configure-databases.sh" --services mongodb --dry-run --yes \
  > "$TEST_ROOT/dry-run.txt"
grep -Fq 'dry run complete' "$TEST_ROOT/dry-run.txt"
[[ ! -e "$dry_state/database-services" ]]

if HOME="$TEST_HOME" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE" \
  MOCK_DOCKER_INFO_FAIL=1 MOCK_DOCKER_STATE="$MOCK_STATE" MOCK_DOCKER_LOG="$MOCK_LOG" \
  PATH="$MOCK_BIN:/usr/bin:/bin:/usr/sbin:/sbin" \
  "$SCRIPT_DIR/configure-databases.sh" --saved --yes \
  > "$TEST_ROOT/unreachable.txt" 2>&1; then
  printf 'FAIL: database installer accepted an unreachable Docker server\n' >&2
  exit 1
fi
grep -Fq 'Docker is installed, but its server is not reachable' "$TEST_ROOT/unreachable.txt"
grep -Fq 'Do not run Docker with sudo' "$TEST_ROOT/unreachable.txt"

printf 'PASS: optional database install, resume, dry-run, status, and Docker diagnostics\n'
