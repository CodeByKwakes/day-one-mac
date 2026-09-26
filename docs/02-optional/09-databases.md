[← Required Phase 8](../01-required/08-verify-and-reproduce.md) · **🤖 ⚙️ Optional 9** · [AI clients →](10-ai-agents.md)

# Optional 9 — Local databases with containers

**Time:** 15–45 minutes · **Required:** only when a current project needs it

In this guide, a Docker **volume** means persistent database data stored
separately from its container. It is not the encrypted external backup volume
used by Stage 0.

## Outcome

A selected database runs in an isolated container with a named volume, a health
check, documented development credentials, and an explicit backup/removal
procedure. Skipping this module does not affect the required setup.

## Choose one path

Both paths create the same container names, volumes, ports, and health checks.
Do not mix paths during the initial setup.

### Script-assisted path — recommended

If Databases was saved in the Optional Setup Center, install or resume exactly
those services:

```bash
day-one-mac databases --saved
```

Or name the services directly:

```bash
day-one-mac databases --services postgres,redis --dry-run
day-one-mac databases --services postgres,redis
```

The installer preserves existing containers and volumes, starts a stopped
selected container, waits for its health check, and writes
`~/.day-one-mac/database-status.md`. Check it later with:

```bash
day-one-mac databases --saved --status
```

When the Docker command or server is unavailable, the installer checks
OrbStack ownership, installs it through the selected approved route when
needed, starts it, adds its bundled `~/.orbstack/bin` tools to the current
process when available, and waits up to 60 seconds for `docker info` to report
a server. OrbStack includes the Docker CLI, Compose, and Buildx; do not install
a second Docker engine or a separate Docker formula for this module.

OrbStack can display first-run permission or licence prompts that automation
must not approve for you. Complete any visible prompt. If the readiness wait
expires, confirm that OrbStack reports Docker as running, verify that
`docker info` shows a **Server** section, and rerun the same command. Do not run
Docker with `sudo`.

After the installer passes, continue at [Step 9.7](#step-97--daily-lifecycle-commands)
to learn the lifecycle and backup commands.

### Fully manual path

Complete Steps 9.1–9.6 below in order. Run only the service blocks selected in
Step 9.1, then complete the same lifecycle, backup, and checklist sections as
the script-assisted path.

## Step 9.1 — Choose only what is needed

| Service | Default port | Add it when |
|---|---:|---|
| PostgreSQL | 5432 | Relational application data is required |
| Redis | 6379 | A cache, queue, session store, or pub/sub service is required |
| MongoDB | 27017 | A project explicitly uses MongoDB |

Do not start all services “just in case.” A repository-owned `compose.yaml` is
preferable when the service belongs to one project. The commands below provide
a simple machine-level development service without requiring Docker Compose.

## Step 9.2 — Manual path: install and start OrbStack

```bash
day-one-mac applications --id orbstack --install-missing
open -a OrbStack
```

The first command checks ownership before changing anything. When OrbStack is
missing, choose Homebrew or select another approved installer and return to the
terminal for a live recheck. If Company Portal or a
manual installer already supplied `/Applications/OrbStack.app`, it reports an
external installation and leaves it unchanged. Deselecting Databases later
does not uninstall OrbStack.

Wait until OrbStack reports that Docker is running, then verify:

```bash
docker version
docker info
docker context show
```

The server section must be present. If only the client appears, open OrbStack
and wait for its Linux environment to start.

## Step 9.3 — Manual path: create a shared development network

```bash
docker network inspect dev-net >/dev/null 2>&1 || \
  docker network create dev-net
```

This makes later project containers able to reach a database by container name
without exposing additional internal ports.

## Step 9.4 — Manual path: PostgreSQL option

This uses `postgres` for the development-only username, password, and default
database, matching the common one-line setup while adding persistence and a
health check:

```bash
docker volume inspect dev-pgdata >/dev/null 2>&1 || \
  docker volume create dev-pgdata

docker run -d \
  --name dev-postgres \
  --network dev-net \
  --restart unless-stopped \
  -p 127.0.0.1:5432:5432 \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=postgres \
  -e PGDATA=/var/lib/postgresql/data/pgdata \
  -v dev-pgdata:/var/lib/postgresql/data \
  --health-cmd='pg_isready -U postgres -d postgres' \
  --health-interval=10s \
  --health-timeout=5s \
  --health-retries=5 \
  postgres:17-alpine
```

These credentials are acceptable only for local development. Do not reuse them
in a deployed environment.

Verify:

```bash
docker inspect --format='{{.State.Health.Status}}' dev-postgres
docker exec dev-postgres psql -U postgres -d postgres -c 'select version();'
```

Connection URL from macOS:

```text
postgresql://postgres:postgres@localhost:5432/postgres
```

## Step 9.5 — Manual path: Redis option

```bash
docker volume inspect dev-redisdata >/dev/null 2>&1 || \
  docker volume create dev-redisdata

docker run -d \
  --name dev-redis \
  --network dev-net \
  --restart unless-stopped \
  -p 127.0.0.1:6379:6379 \
  -v dev-redisdata:/data \
  --health-cmd='redis-cli ping' \
  --health-interval=10s \
  --health-timeout=5s \
  --health-retries=5 \
  redis:7-alpine \
  redis-server --appendonly yes --appendfsync everysec
```

Verify:

```bash
docker inspect --format='{{.State.Health.Status}}' dev-redis
docker exec dev-redis redis-cli ping
```

## Step 9.6 — Manual path: MongoDB option

```bash
docker volume inspect dev-mongodata >/dev/null 2>&1 || \
  docker volume create dev-mongodata

docker run -d \
  --name dev-mongo \
  --network dev-net \
  --restart unless-stopped \
  -p 127.0.0.1:27017:27017 \
  -e MONGO_INITDB_ROOT_USERNAME=dev \
  -e MONGO_INITDB_ROOT_PASSWORD=dev \
  -v dev-mongodata:/data/db \
  --health-cmd='mongosh --quiet --username dev --password dev --authenticationDatabase admin --eval "quit(db.runCommand({ ping: 1 }).ok ? 0 : 2)"' \
  --health-interval=10s \
  --health-timeout=5s \
  --health-retries=5 \
  mongo:8
```

Verify:

```bash
docker inspect --format='{{.State.Health.Status}}' dev-mongo
docker exec dev-mongo mongosh \
  --username dev --password dev --authenticationDatabase admin \
  --eval 'db.runCommand({ ping: 1 })'
```

## Optional graphical database client

DBeaver Community is available when a project benefits from browsing schemas,
running reviewed queries, or comparing more than one database engine. It is not
needed for the container health checks and is never installed automatically:

```bash
day-one-mac applications --id dbeaver-community
day-one-mac applications --id dbeaver-community --install-missing
```

The first command is read-only. In the second command, choose Homebrew or an
approved external installer only after reviewing the displayed owner. Store
saved production credentials in the approved secret manager; do not commit
them in a DBeaver project or export. Use the localhost development credentials
from this guide only with the local containers.

## Step 9.7 — Daily lifecycle commands

```bash
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
docker stop dev-postgres dev-redis dev-mongo    # name only those installed
docker start dev-postgres dev-redis dev-mongo
docker logs --tail 100 dev-postgres
docker stats --no-stream
```

Stopping a container keeps its named volume. Removing a container also keeps
the volume unless the volume is explicitly deleted.

## Step 9.8 — Back up before destructive work

PostgreSQL logical backup:

```bash
mkdir -p "$HOME/Backups/databases"
docker exec dev-postgres pg_dumpall -U postgres \
  > "$HOME/Backups/databases/postgres-$(date +%Y%m%d-%H%M%S).sql"
```

Test that the output is non-empty:

```bash
ls -lh "$HOME/Backups/databases"/*.sql
```

`~/Backups` is still on the Mac's main drive. It protects against an accidental
container or volume deletion, but not against loss or failure of the Mac. Copy
the verified dump to an encrypted external volume or approved remote backup
before any destructive database work.

Redis and MongoDB need project-appropriate backup procedures. A named Docker
volume is persistence, not an independent backup.

## Step 9.9 — Remove safely

Remove containers but keep data:

```bash
docker rm -f dev-postgres dev-redis dev-mongo   # name only those installed
```

Delete data only after reviewing backups:

```bash
docker volume rm dev-pgdata dev-redisdata dev-mongodata
docker network rm dev-net
```

The broad clean-state script preserves container data by default. Its separate
`--archive-docker-data` and `--archive-orbstack-data` options move the selected
runtime's known storage into the recovery archive. It does not silently delete
volumes. See [Upgrade notes](../20-reference/UPGRADE-NOTES.md) only when an
existing automation still uses an earlier flag name.

## Optional completion checklist 🚦

- [ ] Only required services were installed.
- [ ] The application ownership report identifies who manages OrbStack.
- [ ] `docker version` includes a server.
- [ ] Every selected container is healthy or responds to its ping query.
- [ ] Ports are bound to localhost and do not conflict with another service.
- [ ] Development credentials are not reused outside this Mac.
- [ ] DBeaver is installed only if a graphical client is useful, and its saved
      connections contain no committed or exported production secrets.
- [ ] A backup and explicit volume-deletion procedure are understood.
- [ ] `day-one-mac databases --saved --check` passes (script-assisted path), or each manual ping query passes.

---

[← Required Phase 8](../01-required/08-verify-and-reproduce.md) · [AI clients (optional) →](10-ai-agents.md)
