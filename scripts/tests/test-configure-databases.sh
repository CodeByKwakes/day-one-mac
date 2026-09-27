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
MOCK_ORB_LOG="$TEST_ROOT/orb.log"
export MOCK_BIN MOCK_ORB_LOG
mkdir -p "$TEST_STATE/completed" "$MOCK_BIN" "$MOCK_STATE"
printf 'complete\n' > "$TEST_STATE/completed/08"

cat > "$MOCK_BIN/docker" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >> "$MOCK_DOCKER_LOG"
case "${1:-}" in
  info)
    [[ "${MOCK_DOCKER_INFO_FAIL:-0}" != 1 ]] || exit 1
    if [[ "${MOCK_DOCKER_REQUIRE_ORB_START:-0}" == 1 ]]; then
      [[ -f "$MOCK_DOCKER_STATE/orbstack-started" ]] || exit 1
    fi
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
    if [[ "$2" == *Config.Image* ]]; then
      if [[ "${MOCK_CONFIG_CONFLICT:-0}" == 1 ]]; then printf 'conflicting-config\n'; exit 0; fi
      case "$name" in
        dev-postgres) printf 'postgres:17-alpine|127.0.0.1:5432|dev-pgdata:/var/lib/postgresql/data;|dev-net\n' ;;
        dev-redis) printf 'redis:7-alpine|127.0.0.1:6379|dev-redisdata:/data;|dev-net\n' ;;
        dev-mongo) printf 'mongo:8|127.0.0.1:27017|dev-mongodata:/data/db;|dev-net\n' ;;
      esac
    elif [[ "$2" == *State.Running* && "$2" != *State.Health* ]]; then printf 'true\n'; else printf '%s\n' "${MOCK_HEALTH:-healthy}"; fi
    ;;
  run)
    [[ "$2" == -d ]]
    name=''
    while (( $# )); do
      if [[ "$1" == --name ]]; then name="$2"; break; fi
      shift
    done
    [[ -n "$name" ]]
    [[ "${MOCK_FAIL_RUN:-}" != "$name" ]] || exit 8
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

cat > "$MOCK_BIN/orb" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >> "$MOCK_ORB_LOG"
[[ "${1:-}" == start ]]
touch "$MOCK_DOCKER_STATE/orbstack-started"
if [[ "${MOCK_ORB_INSTALL_DOCKER:-0}" == 1 && -x "$MOCK_BIN/docker.pending" ]]; then
  mv "$MOCK_BIN/docker.pending" "$MOCK_BIN/docker"
fi
EOF
chmod +x "$MOCK_BIN/orb"

run_databases() {
  HOME="$TEST_HOME" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE" \
    MOCK_DOCKER_STATE="$MOCK_STATE" MOCK_DOCKER_LOG="$MOCK_LOG" \
    PATH="$MOCK_BIN:/usr/bin:/bin:/usr/sbin:/sbin" \
    "$SCRIPT_DIR/configure-databases.sh" "$@"
}

# A stopped engine is not permission to start OrbStack during a preview.
MOCK_DOCKER_REQUIRE_ORB_START=1 run_databases --services postgres --dry-run \
  > "$TEST_ROOT/stopped-engine-preview.txt"
if grep -Fq 'Starting OrbStack' "$TEST_ROOT/stopped-engine-preview.txt"; then
  printf 'FAIL: preview entered the OrbStack startup path\n' >&2
  exit 1
fi
[[ ! -e "$MOCK_ORB_LOG" ]]
[[ ! -e "$MOCK_STATE/orbstack-started" ]]
[[ ! -e "$TEST_STATE/database-services" ]]
if grep -Eq '^(run|start|network create|volume create)' "$MOCK_LOG"; then
  printf 'FAIL: preview mutated Docker resources\n' >&2
  exit 1
fi

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

# OrbStack owns both the Docker CLI and server. The installer must start it
# when the command is present but the engine has not started yet.
rm -f "$MOCK_STATE/orbstack-started"
MOCK_DOCKER_REQUIRE_ORB_START=1 DAY_ONE_MAC_DOCKER_WAIT_SECONDS=4 \
  run_databases --saved --yes > "$TEST_ROOT/orbstack-server-start.txt"
grep -Fq 'Starting OrbStack to provide its bundled Docker CLI and engine' \
  "$TEST_ROOT/orbstack-server-start.txt"
grep -Fqx 'start' "$MOCK_ORB_LOG"

# A first OrbStack start may create its bundled docker command. Refresh PATH
# and command lookup before deciding that another Docker package is needed.
mv "$MOCK_BIN/docker" "$MOCK_BIN/docker.pending"
rm -f "$MOCK_STATE/orbstack-started"
MOCK_ORB_INSTALL_DOCKER=1 DAY_ONE_MAC_DOCKER_WAIT_SECONDS=4 \
  run_databases --saved --yes > "$TEST_ROOT/orbstack-cli-install.txt"
[[ -x "$MOCK_BIN/docker" ]]
grep -Fq 'OrbStack Docker CLI and server are ready' \
  "$TEST_ROOT/orbstack-cli-install.txt"

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
  DAY_ONE_MAC_DOCKER_WAIT_SECONDS=1 \
  PATH="$MOCK_BIN:/usr/bin:/bin:/usr/sbin:/sbin" \
  "$SCRIPT_DIR/configure-databases.sh" --saved --yes \
  > "$TEST_ROOT/unreachable.txt" 2>&1; then
  printf 'FAIL: database installer accepted an unreachable Docker server\n' >&2
  exit 1
fi
grep -Fq 'Docker is installed, but its server is not reachable' "$TEST_ROOT/unreachable.txt"
grep -Fq 'Do not run Docker with sudo' "$TEST_ROOT/unreachable.txt"

# Unknown or conflicting containers must not be started or replaced.
mutation_count="$(grep -Ec '^(run|start|network create|volume create)' "$MOCK_LOG")"
if MOCK_CONFIG_CONFLICT=1 run_databases --saved --yes > "$TEST_ROOT/conflict.txt" 2>&1; then
  printf 'FAIL: apply accepted conflicting existing container\n' >&2; exit 1
fi
grep -Fq 'conflicts with the expected' "$TEST_ROOT/conflict.txt"
[[ "$mutation_count" == "$(grep -Ec '^(run|start|network create|volume create)' "$MOCK_LOG")" ]]
if MOCK_HEALTH=running run_databases --saved --check > "$TEST_ROOT/no-health.txt" 2>&1; then
  printf 'FAIL: running without health check counted as verified\n' >&2; exit 1
fi

# A later failure retains approved choices and earlier resources for resume.
if MOCK_FAIL_RUN=dev-mongo run_databases --services postgres,mongodb --yes > "$TEST_ROOT/partial.txt" 2>&1; then
  printf 'FAIL: container creation failure was ignored\n' >&2; exit 1
fi
grep -Fxq 'postgres,mongodb' "$TEST_STATE/database-services"
grep -Fq '(incomplete)' "$TEST_ROOT/partial.txt"
run_databases --saved --yes > "$TEST_ROOT/recovered.txt"
run_databases --saved --check > "$TEST_ROOT/recovered-check.txt"
grep -Fq 'mongodb — healthy' "$TEST_ROOT/recovered-check.txt"
find "$TEST_STATE/module-runs/09" -name backups.tsv -exec cat {} + > "$TEST_ROOT/backups.txt"
grep -Fq "$TEST_STATE/database-services" "$TEST_ROOT/backups.txt"

# Public planning works with no Phase 8 marker and creates no saved state.
env DAY_ONE_MAC_STATE_ROOT="$TEST_ROOT/no-phase" DAY_ONE_MAC_STATE_DIR="$TEST_ROOT/no-phase" \
  DAY_ONE_MAC_ORBSTACK_CLI_DIR="$TEST_ROOT/no-orb-cli" MOCK_DOCKER_INFO_FAIL=1 \
  MOCK_DOCKER_STATE="$MOCK_STATE" MOCK_DOCKER_LOG="$MOCK_LOG" \
  PATH="$MOCK_BIN:/usr/bin:/bin:/usr/sbin:/sbin" \
  "$SCRIPT_DIR/day-one-mac" optional --module 09 --plan --services redis \
  > "$TEST_ROOT/no-phase-preview.txt"
[[ ! -e "$TEST_ROOT/no-phase" && ! -e "$TEST_ROOT/no-phase.operation.lock" ]]
grep -Fq 'conditional on absence' "$TEST_ROOT/no-phase-preview.txt"

printf 'PASS: optional database install, resume, dry-run, status, and Docker diagnostics\n'
