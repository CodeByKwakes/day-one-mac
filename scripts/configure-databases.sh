#!/usr/bin/env bash
# Install, resume, and verify the optional local database containers.
# Compatible with the Bash 3.2 shipped by macOS.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/project-paths.sh"
source "$SCRIPT_DIR/lib/terminal-ui.sh"

STATE_ROOT="$(day_one_state_root)"
STATE_DIR="$(day_one_state_dir "$STATE_ROOT")"
COMPLETED_DIR="$STATE_DIR/optional-completed"
REPORT="$STATE_DIR/database-status.md"
SERVICES=""
ACTION=install
DRY_RUN=0
ASSUME_YES=0
ORBSTACK_CLI_DIR="${DAY_ONE_MAC_ORBSTACK_CLI_DIR:-$HOME/.orbstack/bin}"
DOCKER_WAIT_SECONDS="${DAY_ONE_MAC_DOCKER_WAIT_SECONDS:-60}"

usage() {
  cat <<'EOF'
Usage: ./configure-databases.sh [options]

Install or resume selected local development databases in Docker containers.

  --services CSV   postgres, redis, mongodb, or a comma-separated selection
  --saved          use the services saved by `day-one-mac optional`
  --status         show selected container state without changing anything
  --check          verify every selected service; exit non-zero if not ready
  --dry-run        print the Docker operations without changing anything
  --yes            accept the reviewed installation without prompting
  -h, --help       show this help

Existing containers and named volumes are preserved. A stopped selected
container is started; an existing container is never silently replaced.
EOF
}

info() { ui_info "$@"; }
ok() { ui_success "$@"; }
warn() { ui_warning "$@"; }
err() { ui_error "$@"; }

contains_csv() {
  case ",$1," in *",$2,"*) return 0 ;; *) return 1 ;; esac
}

normalize_services() {
  local raw="$1" token result="" old_ifs="$IFS"
  raw="${raw// /}"
  IFS=','
  for token in $raw; do
    case "$token" in
      postgres|redis|mongodb) ;;
      mongo) token=mongodb ;;
      '') continue ;;
      *) err "unknown database service: $token"; return 2 ;;
    esac
    contains_csv "$result" "$token" || result="${result}${result:+,}$token"
  done
  IFS="$old_ifs"
  SERVICES="$result"
  [[ -n "$SERVICES" ]] || { err 'select at least one service'; return 2; }
}

saved_services() {
  [[ -r "$STATE_DIR/database-services" ]] && sed -n '1p' "$STATE_DIR/database-services" || true
}

service_container() {
  case "$1" in
    postgres) printf 'dev-postgres\n' ;;
    redis) printf 'dev-redis\n' ;;
    mongodb) printf 'dev-mongo\n' ;;
  esac
}

service_volume() {
  case "$1" in
    postgres) printf 'dev-pgdata\n' ;;
    redis) printf 'dev-redisdata\n' ;;
    mongodb) printf 'dev-mongodata\n' ;;
  esac
}

service_port() {
  case "$1" in
    postgres) printf '5432\n' ;;
    redis) printf '6379\n' ;;
    mongodb) printf '27017\n' ;;
  esac
}

run_or_preview() {
  if [[ "$DRY_RUN" == 1 ]]; then
    printf '  $'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

docker_server_ready() {
  docker info >/dev/null 2>&1
}

refresh_orbstack_cli_path() {
  if [[ -d "$ORBSTACK_CLI_DIR" && ":$PATH:" != *":$ORBSTACK_CLI_DIR:"* ]]; then
    PATH="$ORBSTACK_CLI_DIR:$PATH"
    export PATH
  fi
  hash -r 2>/dev/null || true
}

orbstack_available() {
  command -v orb >/dev/null 2>&1 \
    || [[ -d "${DAY_ONE_MAC_APPLICATIONS_ROOT:-/Applications}/OrbStack.app" ]] \
    || [[ -d "$HOME/Applications/OrbStack.app" ]]
}

start_orbstack() {
  if command -v orb >/dev/null 2>&1 && orb start; then
    return 0
  fi
  command -v open >/dev/null 2>&1 && open -a OrbStack
}

wait_for_docker_ready() {
  local deadline
  deadline=$((SECONDS + DOCKER_WAIT_SECONDS))
  while (( SECONDS < deadline )); do
    refresh_orbstack_cli_path
    if command -v docker >/dev/null 2>&1 && docker_server_ready; then return 0; fi
    sleep 2
  done
  refresh_orbstack_cli_path
  command -v docker >/dev/null 2>&1 && docker_server_ready
}

start_orbstack_and_wait() {
  info 'Starting OrbStack to provide its bundled Docker CLI and engine.'
  warn 'Complete any first-run prompts shown by OrbStack; the installer will wait for Docker readiness.'
  start_orbstack || {
    warn 'OrbStack could not be started automatically.'
    return 1
  }
  if wait_for_docker_ready; then
    ok 'OrbStack Docker CLI and server are ready'
    return 0
  fi
  return 1
}

ensure_docker() {
  local context orbstack_attempted=0
  [[ "$DOCKER_WAIT_SECONDS" =~ ^[0-9]+$ && "$DOCKER_WAIT_SECONDS" -gt 0 ]] || {
    err 'DAY_ONE_MAC_DOCKER_WAIT_SECONDS must be a positive integer.'
    return 2
  }
  refresh_orbstack_cli_path
  if ! command -v docker >/dev/null 2>&1; then
    if [[ "$DRY_RUN" == 1 ]]; then
      info 'Docker is missing; the installer would offer OrbStack through the application ownership flow.'
      printf '  $ %q %q %q %q %q\n' "$SCRIPT_DIR/application-status.sh" --id orbstack --install-missing --app-install-policy
      printf '    %q\n' homebrew
      return 0
    fi
    if orbstack_available; then
      orbstack_attempted=1
      start_orbstack_and_wait || true
    fi
  fi
  if ! command -v docker >/dev/null 2>&1; then
    "$SCRIPT_DIR/application-status.sh" --id orbstack --install-missing
    refresh_orbstack_cli_path
  fi
  if orbstack_available \
     && { ! command -v docker >/dev/null 2>&1 || ! docker_server_ready; } \
     && [[ "$orbstack_attempted" == 0 ]]; then
    orbstack_attempted=1
    start_orbstack_and_wait || true
  fi
  command -v docker >/dev/null 2>&1 || {
    err 'Docker is unavailable after installing or checking OrbStack.'
    warn 'Open OrbStack, finish its first-run setup, and wait until Docker is running.'
    warn "OrbStack bundles Docker and normally exposes it through $ORBSTACK_CLI_DIR; do not install a second Docker engine."
    return 1
  }
  [[ "$DRY_RUN" == 1 ]] && return 0
  if ! docker_server_ready; then
    context="$(docker context show 2>/dev/null || printf unknown)"
    err "Docker is installed, but its server is not reachable (context: $context)."
    if [[ "$orbstack_attempted" == 1 ]]; then
      warn "OrbStack did not become ready within $DOCKER_WAIT_SECONDS seconds. Complete any visible first-run prompt, then rerun the same command."
    else
      warn 'Open the application that owns this Docker context, wait until its engine is running, then rerun the same command.'
    fi
    warn 'Use `docker info` to confirm the Server section is available. Do not run Docker with sudo.'
    return 1
  fi
}

container_exists() {
  docker container inspect "$1" >/dev/null 2>&1
}

container_running() {
  [[ "$(docker inspect --format='{{.State.Running}}' "$1" 2>/dev/null || true)" == true ]]
}

container_health() {
  docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}{{if .State.Running}}running{{else}}stopped{{end}}{{end}}' "$1" 2>/dev/null || printf 'missing\n'
}

ensure_network() {
  if [[ "$DRY_RUN" == 1 ]]; then
    info 'ensure Docker network: dev-net'
    run_or_preview docker network create dev-net
  elif docker network inspect dev-net >/dev/null 2>&1; then
    ok 'Docker network dev-net already exists'
  else
    docker network create dev-net >/dev/null
    ok 'created Docker network dev-net'
  fi
}

ensure_volume() {
  local volume="$1"
  if [[ "$DRY_RUN" == 1 ]]; then
    info "ensure named volume: $volume"
    run_or_preview docker volume create "$volume"
  elif docker volume inspect "$volume" >/dev/null 2>&1; then
    ok "named volume $volume already exists"
  else
    docker volume create "$volume" >/dev/null
    ok "created named volume $volume"
  fi
}

create_container() {
  local service="$1"
  case "$service" in
    postgres)
      run_or_preview docker run -d --name dev-postgres --network dev-net \
        --restart unless-stopped -p 127.0.0.1:5432:5432 \
        -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres \
        -e POSTGRES_DB=postgres -e PGDATA=/var/lib/postgresql/data/pgdata \
        -v dev-pgdata:/var/lib/postgresql/data \
        --health-cmd='pg_isready -U postgres -d postgres' \
        --health-interval=10s --health-timeout=5s --health-retries=5 \
        postgres:17-alpine
      ;;
    redis)
      run_or_preview docker run -d --name dev-redis --network dev-net \
        --restart unless-stopped -p 127.0.0.1:6379:6379 \
        -v dev-redisdata:/data --health-cmd='redis-cli ping' \
        --health-interval=10s --health-timeout=5s --health-retries=5 \
        redis:7-alpine redis-server --appendonly yes --appendfsync everysec
      ;;
    mongodb)
      run_or_preview docker run -d --name dev-mongo --network dev-net \
        --restart unless-stopped -p 127.0.0.1:27017:27017 \
        -e MONGO_INITDB_ROOT_USERNAME=dev -e MONGO_INITDB_ROOT_PASSWORD=dev \
        -v dev-mongodata:/data/db \
        --health-cmd='mongosh --quiet --username dev --password dev --authenticationDatabase admin --eval "quit(db.runCommand({ ping: 1 }).ok ? 0 : 2)"' \
        --health-interval=10s --health-timeout=5s --health-retries=5 mongo:8
      ;;
  esac
}

wait_for_service() {
  local service="$1" container status attempts=0
  container="$(service_container "$service")"
  while (( attempts < 15 )); do
    status="$(container_health "$container")"
    case "$status" in
      healthy|running) ok "$service is ready ($status)"; return 0 ;;
      unhealthy) err "$service container is unhealthy"; docker logs --tail 40 "$container" >&2 || true; return 1 ;;
    esac
    attempts=$((attempts + 1))
    sleep 2
  done
  err "$service did not become ready within 30 seconds (last state: $status)"
  docker logs --tail 40 "$container" >&2 || true
  return 1
}

install_service() {
  local service="$1" container volume
  container="$(service_container "$service")"
  volume="$(service_volume "$service")"
  ensure_volume "$volume"
  if [[ "$DRY_RUN" == 1 ]]; then
    create_container "$service"
    return 0
  fi
  if container_exists "$container"; then
    if container_running "$container"; then
      ok "$container already exists and is running"
    else
      info "starting existing container $container"
      docker start "$container" >/dev/null
    fi
  else
    info "creating $container"
    create_container "$service" >/dev/null
  fi
  wait_for_service "$service"
}

write_report() {
  local service container health port temporary
  mkdir -p "$STATE_DIR" "$COMPLETED_DIR"
  chmod 700 "$STATE_DIR" "$COMPLETED_DIR"
  temporary="$(mktemp "$STATE_DIR/.database-status.XXXXXX")"
  {
    printf '# Local database status\n\n'
    printf 'Generated: `%s`\n\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    printf '| Service | Container | Port | State |\n|---|---|---:|---|\n'
    for service in postgres redis mongodb; do
      contains_csv "$SERVICES" "$service" || continue
      container="$(service_container "$service")"
      port="$(service_port "$service")"
      health="$(container_health "$container")"
      printf '| %s | `%s` | %s | %s |\n' "$service" "$container" "$port" "$health"
    done
  } > "$temporary"
  chmod 600 "$temporary"
  mv "$temporary" "$REPORT"
}

show_status() {
  local service container health failures=0
  ui_title '🗄️' 'Optional databases'
  if ! command -v docker >/dev/null 2>&1; then
    err 'Docker command is missing'
    return 1
  fi
  if ! docker_server_ready; then
    err 'Docker server is not reachable'
    return 1
  fi
  for service in postgres redis mongodb; do
    contains_csv "$SERVICES" "$service" || continue
    container="$(service_container "$service")"
    health="$(container_health "$container")"
    case "$health" in
      healthy|running) ui_status success "✓ $service — $health ($container)" ;;
      *) ui_status pending "○ $service — $health ($container)"; failures=$((failures + 1)) ;;
    esac
  done
  [[ "$failures" -eq 0 ]]
}

while (( $# )); do
  case "$1" in
    --services) [[ "$#" -ge 2 ]] || { err '--services needs a comma-separated value'; exit 2; }; SERVICES="$2"; shift 2 ;;
    --saved) SERVICES="$(saved_services)"; shift ;;
    --status) ACTION=status; shift ;;
    --check) ACTION=check; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --yes) ASSUME_YES=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) err "unknown option: $1"; usage >&2; exit 2 ;;
  esac
done

[[ -n "$SERVICES" ]] || SERVICES="$(saved_services)"
normalize_services "$SERVICES"

if [[ "$ACTION" == status || "$ACTION" == check ]]; then
  if show_status; then exit 0; else exit 1; fi
fi

[[ -s "$STATE_DIR/completed/08" ]] || {
  err 'Required Phase 8 is not recorded complete. Finish the base before adding databases.'
  exit 10
}

ui_title '🗄️' 'Install optional local databases'
info "selected services: $SERVICES"
info 'Existing containers and volumes will be preserved.'
if [[ "$DRY_RUN" != 1 && "$ASSUME_YES" != 1 ]]; then
  [[ -t 0 ]] || { err 'installation confirmation needs a terminal or --yes'; exit 10; }
  printf 'Install or resume these database services? [y/N]: '
  IFS= read -r answer
  [[ "$answer" == y || "$answer" == Y || "$answer" == yes || "$answer" == YES ]] || exit 10
fi

ensure_docker
ensure_network
for service in postgres redis mongodb; do
  contains_csv "$SERVICES" "$service" || continue
  install_service "$service"
done

if [[ "$DRY_RUN" == 1 ]]; then
  info 'dry run complete; no Docker resources or state files were changed'
  exit 0
fi

printf '%s\n' "$SERVICES" > "$STATE_DIR/database-services"
chmod 600 "$STATE_DIR/database-services"
write_report
if show_status; then
  printf '%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" > "$COMPLETED_DIR/databases"
  chmod 600 "$COMPLETED_DIR/databases"
  ok "database setup completed; report: $REPORT"
else
  err 'database setup is incomplete; review the status above and rerun this command'
  exit 1
fi
