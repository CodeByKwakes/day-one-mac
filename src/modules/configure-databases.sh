#!/usr/bin/env bash
# Install, resume, and verify the optional local database containers.
# Compatible with the Bash 3.2 shipped by macOS.
set -euo pipefail

DAY_ONE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_DIR="$DAY_ONE_ROOT/scripts"
source "$SCRIPT_DIR/../src/core/project-paths.sh"
source "$SCRIPT_DIR/../src/core/terminal-ui.sh"
source "$SCRIPT_DIR/../src/core/module-execution.sh"
source "$SCRIPT_DIR/../src/core/container-runtime.sh"
ORIGINAL_ARGS=("$@")

STATE_ROOT="$(day_one_state_root)"
STATE_DIR="$(day_one_state_dir "$STATE_ROOT")"
COMPLETED_DIR="$STATE_DIR/optional-completed"
REPORT="$STATE_DIR/database-status.md"
SERVICES=""
ACTION=install
CONTAINER_RUNTIME=auto
DRY_RUN=0
ASSUME_YES=0
USE_SAVED=0
DOCKER_INSPECTABLE=0
DB_CONTEXT=""
DB_ENDPOINT=""
DISPOSABLE_DATA=0
ORBSTACK_CLI_DIR="${DAY_ONE_MAC_ORBSTACK_CLI_DIR:-$HOME/.orbstack/bin}"
DOCKER_WAIT_SECONDS="${DAY_ONE_MAC_DOCKER_WAIT_SECONDS:-60}"

usage() {
  cat <<'EOF'
Usage: ./configure-databases.sh [options]

Install or resume selected local development databases in Docker containers.

  --services CSV   postgres, redis, mongodb, or a comma-separated selection
  --container-runtime auto|docker|orbstack
                   reuse an existing engine or choose Docker Desktop / OrbStack
  --disposable-data acknowledge fixed development credentials; synthetic data only
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

service_image() {
  if [[ -r "$STATE_DIR/database-image-$1" ]]; then cat "$STATE_DIR/database-image-$1"
  else case "$1" in postgres) printf 'postgres:17-alpine' ;; redis) printf 'redis:7-alpine' ;; mongodb) printf 'mongo:8' ;; esac; fi
}

prepare_service_images() {
  local service image digest
  for service in postgres redis mongodb; do
    contains_csv "$SERVICES" "$service" || continue
    image="$(service_image "$service")"
    if [[ "$DRY_RUN" == 1 ]]; then info "Image $service: $image (first apply resolves and records immutable digest)"; continue; fi
    if [[ ! -s "$STATE_DIR/database-image-$service" ]]; then
      if container_exists "$(service_container "$service")"; then err 'Existing database needs explicit migration; no image identity recorded.'; return 10; fi
      db_docker pull "$image" >/dev/null || return 1
      digest="$(db_docker image inspect --format '{{index .RepoDigests 0}}' "$image")" || return 1
      [[ "$digest" =~ ^[a-z0-9./:-]+@sha256:[a-f0-9]{64}$ ]] || { err 'Image did not provide an immutable registry digest.'; return 1; }
      day_one_write_state "$STATE_DIR/database-image-$service" "$digest"
    fi
    image="$(service_image "$service")"
    [[ "$image" =~ ^[a-z0-9./:-]+@sha256:[a-f0-9]{64}$ ]] || return 1
    db_docker image inspect "$image" >/dev/null 2>&1 || db_docker pull "$image" >/dev/null || return 1
  done
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
  verify_selected_context || return $?
  db_docker info >/dev/null 2>&1
}

refresh_orbstack_cli_path() {
  day_one_container_cli_path
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
    if command -v docker >/dev/null 2>&1 && docker --version >/dev/null 2>&1 && docker_server_ready; then return 0; fi
    sleep 2
  done
  refresh_orbstack_cli_path
  command -v docker >/dev/null 2>&1 && docker --version >/dev/null 2>&1 && docker_server_ready
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

# Never let ambient Docker environment variables select another daemon.
verify_selected_context() {
  local expected='' context endpoint recorded
  [[ -z "${DOCKER_HOST:-}${DOCKER_CONTEXT:-}${DOCKER_TLS_VERIFY:-}${DOCKER_CERT_PATH:-}" ]] || {
    err 'Unset Docker endpoint overrides before using the local database module.'; return 10;
  }
  context="$(command docker context show 2>/dev/null)" || return 10
  [[ "$context" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ ]] || return 10
  case "$CONTAINER_RUNTIME" in docker) expected=desktop-linux ;; orbstack) expected=orbstack ;; esac
  [[ -z "$expected" || "$context" == "$expected" ]] || {
    err 'The active Docker context differs from the selected runtime; review it manually.'; return 10;
  }
  endpoint="$(command docker context inspect --format '{{.Endpoints.docker.Host}}' "$context" 2>/dev/null)" || return 10
  [[ "$endpoint" == unix:///* && "$endpoint" != *$'\n'* && "$endpoint" != *$'\t'* ]] || {
    err 'Refusing a non-local or ambiguous Docker endpoint.'; return 10;
  }
  if [[ -s "$STATE_DIR/database-endpoint" ]]; then
    recorded="$(cat "$STATE_DIR/database-endpoint")"
    [[ "$recorded" == "$context"$'\t'"$endpoint" ]] || {
      err 'Database endpoint changed; review the old resources and migration before changing the saved endpoint.'; return 10;
    }
  fi
  DB_CONTEXT="$context"; DB_ENDPOINT="$endpoint"
}

db_docker() {
  [[ -n "$DB_CONTEXT" ]] || { err 'No verified local Docker context.'; return 10; }
  command docker --context "$DB_CONTEXT" "$@"
}

verify_owned_resource() {
  local kind="$1" name="$2" owner
  owner="$(db_docker "$kind" inspect --format '{{index .Labels "com.day-one-mac.owner"}}' "$name")" || return 1
  [[ "$owner" == databases-v2 ]] || { err "Unowned $kind $name: nothing adopted or replaced. Review and migrate manually."; return 1; }
}

ensure_docker() {
  local context orbstack_attempted=0
  [[ "$DOCKER_WAIT_SECONDS" =~ ^[0-9]+$ && "$DOCKER_WAIT_SECONDS" -gt 0 ]] || {
    err 'DAY_ONE_MAC_DOCKER_WAIT_SECONDS must be a positive integer.'
    return 2
  }
  refresh_orbstack_cli_path
  if command -v docker >/dev/null 2>&1; then verify_selected_context || return $?; fi
  if [[ "$DRY_RUN" == 1 ]]; then
    if command -v docker >/dev/null 2>&1 && docker_server_ready; then
      DOCKER_INSPECTABLE=1
    else
      info 'Docker is unavailable or stopped. Apply uses the selected Docker Desktop or OrbStack engine after approval.'
      info 'Resource state is unknown; the following creates are conditional on absence.'
    fi
    return 0
  fi
  if command -v docker >/dev/null 2>&1 && docker --version >/dev/null 2>&1 && docker_server_ready; then
    verify_selected_context || return $?
    DOCKER_INSPECTABLE=1
    return 0
  fi
  if [[ "$CONTAINER_RUNTIME" == auto ]]; then
    if [[ -d "${DAY_ONE_MAC_APPLICATIONS_ROOT:-/Applications}/Docker.app" || -d "$HOME/Applications/Docker.app" ]]; then
      CONTAINER_RUNTIME=docker
    elif orbstack_available; then CONTAINER_RUNTIME=orbstack
    elif [[ -t 0 ]]; then
      printf 'Container engine: [1] Docker Desktop  [2] OrbStack: '
      IFS= read -r answer
      case "$answer" in 1) CONTAINER_RUNTIME=docker ;; 2) CONTAINER_RUNTIME=orbstack ;; *) err 'Choose Docker Desktop or OrbStack.'; return 10 ;; esac
    else
      err 'Choose --container-runtime docker or --container-runtime orbstack; no existing engine was detected.'
      return 10
    fi
  fi
  day_one_write_state "$STATE_DIR/container-runtime" "$CONTAINER_RUNTIME"
  if [[ "$CONTAINER_RUNTIME" == docker ]]; then
    if [[ ! -d "${DAY_ONE_MAC_APPLICATIONS_ROOT:-/Applications}/Docker.app" && ! -d "$HOME/Applications/Docker.app" ]]; then
      "$SCRIPT_DIR/../src/operations/application-status.sh" --id docker-desktop --install-missing
    fi
    info 'Starting Docker Desktop; complete its first-run prompts.'
    if ! open -a Docker || ! wait_for_docker_ready; then
      warn 'Docker Desktop did not become ready; finish its setup and rerun.'
    fi
  else
    if ! orbstack_available; then
      "$SCRIPT_DIR/../src/operations/application-status.sh" --id orbstack --install-missing
    fi
    orbstack_attempted=1
    start_orbstack_and_wait || true
  fi
  refresh_orbstack_cli_path
  command -v docker >/dev/null 2>&1 || {
    err 'Docker CLI is unavailable after installing or checking the selected engine.'
    warn 'Open the selected container application, finish its first-run setup, and wait until Docker is running.'
    warn 'Verify the bundled CLI location and PATH described in Optional 9 Step 9.2; installing a second engine does not repair PATH.'
    return 1
  }
  docker --version >/dev/null 2>&1 || { err 'Docker CLI is present but cannot run; repair the selected application installation.'; return 1; }
  if ! docker_server_ready; then
    context="$(docker context show 2>/dev/null || printf unknown)"
    err "Docker is installed, but its server is not reachable (context: $context)."
    if [[ "$orbstack_attempted" == 1 ]]; then
      warn "OrbStack did not become ready within $DOCKER_WAIT_SECONDS seconds. Complete any visible first-run prompt, then rerun the same command."
    else
      warn 'Open the application that owns this Docker context, wait until its engine is running, then rerun the same command.'
    fi
    warn 'Use `db_docker info` to confirm the Server section is available. Do not run Docker with sudo.'
    return 1
  fi
  verify_selected_context || return $?
  DOCKER_INSPECTABLE=1
}

container_exists() {
  db_docker container inspect "$1" >/dev/null 2>&1
}

container_running() {
  [[ "$(db_docker inspect --format='{{.State.Running}}' "$1" 2>/dev/null || true)" == true ]]
}

container_health() {
  db_docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}{{if .State.Running}}running{{else}}stopped{{end}}{{end}}' "$1" 2>/dev/null || printf 'missing\n'
}

container_spec_hash() {
  # Immutable launch settings only. Exclude dynamic network addresses/health.
  # Output is hashed before persistence; no environment values enter reports.
  local spec
  spec="$(db_docker inspect --format '{{json .Config}}|{{json .HostConfig}}|{{json .Mounts}}|{{range $key, $value := .NetworkSettings.Networks}}{{$key}};{{end}}' "$1")" || return 1
  [[ -n "$spec" ]] || return 1
  printf '%s' "$spec" | shasum -a 256 | awk '{print $1}'
}

container_matches() {
  local service="$1" container expected actual image destination observed_spec
  container="$(service_container "$service")"
  observed_spec="$(container_spec_hash "$container")" || return 1
  [[ "$observed_spec" =~ ^[a-f0-9]{64}$ && -r "$STATE_DIR/database-spec-$service" && "$(cat "$STATE_DIR/database-spec-$service")" == "$observed_spec" ]] || {
    err "$container conflicts with the expected recorded launch specification; manual review required."; return 1;
  }
  case "$service" in
    postgres) image=postgres:17-alpine; destination=/var/lib/postgresql/data ;;
    redis) image=redis:7-alpine; destination=/data ;;
    mongodb) image=mongo:8; destination=/data/db ;;
  esac
  image="$(service_image "$service")"
  expected="$image|127.0.0.1:$(service_port "$service")|$(service_volume "$service"):$destination;|dev-net"
  local safety
  safety="$(db_docker inspect --format '{{index .Config.Labels "com.day-one-mac.owner"}}|{{.HostConfig.Privileged}}|{{.HostConfig.PidMode}}|{{len .HostConfig.Devices}}|{{len .HostConfig.CapAdd}}|{{json .HostConfig.SecurityOpt}}|{{.HostConfig.Memory}}|{{.HostConfig.NanoCpus}}|{{.HostConfig.RestartPolicy.Name}}|{{len .HostConfig.PortBindings}}|{{len .Mounts}}|{{len .NetworkSettings.Networks}}|{{.HostConfig.PublishAllPorts}}|{{len .HostConfig.VolumesFrom}}' "$container")" || return 1
  [[ "$safety" == 'databases-v2|false||0|0|["no-new-privileges"]|2147483648|2000000000|no|1|1|1|false|0' ]] || {
    err "$container conflicts with the expected ownership/security/resource limits. Nothing changed."; return 1;
  }
  verify_owned_resource volume "$(service_volume "$service")" || return 1
  verify_owned_resource network dev-net || return 1
  actual="$(db_docker inspect --format="{{.Config.Image}}|{{range (index .HostConfig.PortBindings \"$(service_port "$service")/tcp\")}}{{.HostIp}}:{{.HostPort}}{{end}}|{{range .Mounts}}{{if eq .Type \"volume\"}}{{.Name}}:{{.Destination}};{{end}}{{end}}|{{if index .NetworkSettings.Networks \"dev-net\"}}dev-net{{end}}" "$container")" || return 1
  if [[ "$actual" != "$expected" ]]; then
    err "$container conflicts with the expected image, localhost port, volume, or network."
    warn 'Nothing will replace this container. Review its configuration and data before retrying.'
    return 1
  fi
}

preflight_containers() {
  local service container
  [[ "$DOCKER_INSPECTABLE" == 1 ]] || return 0
  for service in postgres redis mongodb; do
    contains_csv "$SERVICES" "$service" || continue
    container="$(service_container "$service")"
    if container_exists "$container"; then container_matches "$service" || return 1; fi
  done
}

ensure_network() {
  if [[ "$DOCKER_INSPECTABLE" == 1 ]] && db_docker network inspect dev-net >/dev/null 2>&1; then
    verify_owned_resource network dev-net || return 1
    ok 'Docker network dev-net already exists'
  elif [[ "$DRY_RUN" == 1 ]]; then
    info 'ensure Docker network: dev-net'
    run_or_preview db_docker network create --label com.day-one-mac.owner=databases-v2 dev-net
  else
    day_one_module_event creating-network dev-net
    db_docker network create --label com.day-one-mac.owner=databases-v2 dev-net >/dev/null
    day_one_module_event created-network dev-net
    ok 'created Docker network dev-net'
  fi
}

ensure_volume() {
  local volume="$1"
  if [[ "$DOCKER_INSPECTABLE" == 1 ]] && db_docker volume inspect "$volume" >/dev/null 2>&1; then
    verify_owned_resource volume "$volume" || return 1
    ok "named volume $volume already exists"
  elif [[ "$DRY_RUN" == 1 ]]; then
    info "ensure named volume: $volume"
    run_or_preview db_docker volume create --label com.day-one-mac.owner=databases-v2 "$volume"
  else
    day_one_module_event creating-volume "$volume"
    db_docker volume create --label com.day-one-mac.owner=databases-v2 "$volume" >/dev/null
    day_one_module_event created-volume "$volume"
    ok "created named volume $volume"
  fi
}

create_container() {
  local service="$1"
  case "$service" in
    postgres)
      run_or_preview db_docker run -d --name dev-postgres --network dev-net \
        --label com.day-one-mac.owner=databases-v2 --memory 2g --cpus 2 --security-opt no-new-privileges --restart no -p 127.0.0.1:5432:5432 \
        -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres \
        -e POSTGRES_DB=postgres -e PGDATA=/var/lib/postgresql/data/pgdata \
        -v dev-pgdata:/var/lib/postgresql/data \
        --health-cmd='pg_isready -U postgres -d postgres' \
        --health-interval=10s --health-timeout=5s --health-retries=5 \
        "$(service_image postgres)"
      ;;
    redis)
      run_or_preview db_docker run -d --name dev-redis --network dev-net \
        --label com.day-one-mac.owner=databases-v2 --memory 2g --cpus 2 --security-opt no-new-privileges --restart no -p 127.0.0.1:6379:6379 \
        -v dev-redisdata:/data --health-cmd='redis-cli ping' \
        --health-interval=10s --health-timeout=5s --health-retries=5 \
        "$(service_image redis)" redis-server --appendonly yes --appendfsync everysec
      ;;
    mongodb)
      run_or_preview db_docker run -d --name dev-mongo --network dev-net \
        --label com.day-one-mac.owner=databases-v2 --memory 2g --cpus 2 --security-opt no-new-privileges --restart no -p 127.0.0.1:27017:27017 \
        -e MONGO_INITDB_ROOT_USERNAME=dev -e MONGO_INITDB_ROOT_PASSWORD=dev \
        -v dev-mongodata:/data/db \
        --health-cmd='mongosh --quiet --username dev --password dev --authenticationDatabase admin --eval "quit(db.runCommand({ ping: 1 }).ok ? 0 : 2)"' \
        --health-interval=10s --health-timeout=5s --health-retries=5 "$(service_image mongodb)"
      ;;
  esac
}

wait_for_service() {
  local service="$1" container status attempts=0
  container="$(service_container "$service")"
  while (( attempts < 15 )); do
    status="$(container_health "$container")"
    case "$status" in
      healthy) ok "$service is ready ($status)"; return 0 ;;
      running) err "$service has no passing health check; refusing to claim readiness"; return 1 ;;
      unhealthy) err "$service container is unhealthy"; db_docker logs --tail 40 "$container" >&2 || true; return 1 ;;
    esac
    attempts=$((attempts + 1))
    sleep 2
  done
  err "$service did not become ready within 30 seconds (last state: $status)"
  db_docker logs --tail 40 "$container" >&2 || true
  return 1
}

install_service() {
  local service="$1" container volume observed_spec
  container="$(service_container "$service")"
  volume="$(service_volume "$service")"
  if [[ "$DOCKER_INSPECTABLE" == 1 ]] && container_exists "$container"; then
    if container_running "$container"; then
      ok "$container already exists and is running"
    else
      info "starting existing container $container"
      day_one_module_event starting-container "$container"
      run_or_preview db_docker start "$container" >/dev/null
      if [[ "$DRY_RUN" == 1 ]]; then info "would start $container"; fi
    fi
  else
    if [[ "$DRY_RUN" == 1 ]]; then info "would create $container if absent"; else info "creating $container"; fi
    ensure_volume "$volume"
    if [[ "$DRY_RUN" == 1 ]]; then create_container "$service"; return 0; fi
    day_one_module_event creating-container "$container"
    create_container "$service" >/dev/null
    observed_spec="$(container_spec_hash "$container")" || return 1
    day_one_write_state "$STATE_DIR/database-spec-$service" "$observed_spec"
    day_one_module_event created-container "$container"
  fi
  [[ "$DRY_RUN" == 0 ]] || return 0
  wait_for_service "$service"
  day_one_module_event healthy "$container"
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
  refresh_orbstack_cli_path
  ui_title '🗄️' 'Optional databases'
  if ! command -v docker >/dev/null 2>&1; then
    err 'Docker command is missing'
    return 1
  fi
  docker --version >/dev/null 2>&1 || { err 'Docker CLI is present but cannot run.'; return 1; }
  if ! docker_server_ready; then
    err 'Docker server is not reachable'
    return 1
  fi
  verify_selected_context || return $?
  for service in postgres redis mongodb; do
    contains_csv "$SERVICES" "$service" || continue
    container="$(service_container "$service")"
    health="$(container_health "$container")"
    case "$health" in
      healthy)
        if container_matches "$service"; then
          ui_status success "✓ $service — $health ($container)"
        else
          failures=$((failures + 1))
        fi
        ;;
      *) ui_status pending "○ $service — $health ($container)"; failures=$((failures + 1)) ;;
    esac
  done
  [[ "$failures" -eq 0 ]]
}

while (( $# )); do
  case "$1" in
    --container-runtime) [[ "$#" -ge 2 ]] || { err '--container-runtime needs auto, docker, or orbstack'; exit 2; }; CONTAINER_RUNTIME="$2"; shift 2 ;;
    --services) [[ "$#" -ge 2 ]] || { err '--services needs a comma-separated value'; exit 2; }; SERVICES="$2"; shift 2 ;;
    --disposable-data) DISPOSABLE_DATA=1; shift ;;
    --saved) USE_SAVED=1; shift ;;
    --status) ACTION=status; shift ;;
    --check) ACTION=check; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --yes) ASSUME_YES=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) err "unknown option: $1"; usage >&2; exit 2 ;;
  esac
done

[[ "$CONTAINER_RUNTIME" != auto || ! -s "$STATE_DIR/container-runtime" ]] || CONTAINER_RUNTIME="$(sed -n '1p' "$STATE_DIR/container-runtime")"
case "$CONTAINER_RUNTIME" in auto|docker|orbstack) ;; *) err 'invalid container runtime'; exit 2 ;; esac

if [[ "$ACTION" == install && "$DRY_RUN" == 0 ]]; then
  day_one_serialize databases "$0" "${ORIGINAL_ARGS[@]}"
fi
[[ "$USE_SAVED" == 0 ]] || SERVICES="$(saved_services)"

[[ -n "$SERVICES" ]] || SERVICES="$(saved_services)"
normalize_services "$SERVICES"
[[ "$DISPOSABLE_DATA" == 1 || ! -r "$STATE_DIR/database-disposable" ]] || DISPOSABLE_DATA="$(cat "$STATE_DIR/database-disposable")"
if [[ "$ACTION" == install && "$DRY_RUN" == 0 && "$DISPOSABLE_DATA" != 1 ]]; then
  err 'Review --plan, then explicitly select --disposable-data. Fixed credentials permit synthetic test data only; use a separately managed service for sensitive data.'
  exit 10
fi

if [[ "$ACTION" == status || "$ACTION" == check ]]; then
  if show_status; then exit 0; else exit 1; fi
fi

if [[ "$DRY_RUN" == 0 ]] && ! day_one_operation_ready; then
  err 'Database installation requires a supported native Apple-silicon environment.'
  exit 10
fi
day_one_operation_ready || warn 'Plan only: apply requires a supported native Apple-silicon environment.'

ui_title '🗄️' 'Install optional local databases'
info "selected services: $SERVICES"
info 'Synthetic disposable data only: fixed development credentials, 2 GiB/2 CPU per service, no automatic restart. Existing unowned resources are refused.'
if [[ "$DRY_RUN" != 1 && "$ASSUME_YES" != 1 ]]; then
  [[ -t 0 ]] || { err 'installation confirmation needs a terminal or --yes'; exit 10; }
  printf 'Install or resume these database services? [y/N]: '
  IFS= read -r answer
  [[ "$answer" == y || "$answer" == Y || "$answer" == yes || "$answer" == YES ]] || exit 10
fi

if [[ "$DRY_RUN" == 0 ]]; then
  day_one_module_begin 09 "$SERVICES" "$STATE_DIR/database-services" "$REPORT" "$COMPLETED_DIR/databases"
  day_one_write_state "$STATE_DIR/database-services" "$SERVICES"
fi
ensure_docker
if [[ "$DRY_RUN" == 0 ]]; then
  day_one_write_state "$STATE_DIR/database-endpoint" "$DB_CONTEXT"$'\t'"$DB_ENDPOINT"
  day_one_write_state "$STATE_DIR/database-disposable" 1
fi
prepare_service_images
preflight_containers
ensure_network
for service in postgres redis mongodb; do
  contains_csv "$SERVICES" "$service" || continue
  install_service "$service"
done

if [[ "$DRY_RUN" == 1 ]]; then
  info 'dry run complete; no Docker resources or state files were changed'
  exit 0
fi

write_report
if show_status; then
  day_one_write_state "$COMPLETED_DIR/databases" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  MODULE_VERIFIED=1
  ok "database setup completed; report: $REPORT"
else
  err 'database setup is incomplete; review the status above and rerun this command'
  exit 1
fi
