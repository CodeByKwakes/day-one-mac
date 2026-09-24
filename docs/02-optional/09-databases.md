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

## Step 9.1 — Choose only what is needed

| Service | Default port | Add it when |
|---|---:|---|
| PostgreSQL | 5432 | Relational application data is required |
| Redis | 6379 | A cache, queue, session store, or pub/sub service is required |
| MongoDB | 27017 | A project explicitly uses MongoDB |

Do not start all services “just in case.” A repository-owned `compose.yaml` is
preferable when the service belongs to one project. The commands below provide
a simple machine-level development service without requiring Docker Compose.

## Step 9.2 — Install and start OrbStack

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

## Step 9.3 — Create a shared development network

```bash
docker network inspect dev-net >/dev/null 2>&1 || \
  docker network create dev-net
```

This makes later project containers able to reach a database by container name
without exposing additional internal ports.

## Step 9.4 — PostgreSQL option

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

## Step 9.5 — Redis option

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

## Step 9.6 — MongoDB option

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
- [ ] A backup and explicit volume-deletion procedure are understood.

---

[← Required Phase 8](../01-required/08-verify-and-reproduce.md) · [AI clients (optional) →](10-ai-agents.md)
