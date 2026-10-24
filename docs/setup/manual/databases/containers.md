# Run disposable local database containers

Use this complete manual task only for synthetic, disposable local data. Prefer
a project's reviewed Compose configuration when it already defines its services.
This task has no Day One Mac ownership record or automated rollback.

## Before you start

Choose one engine and only the services you need. Inspect existing Docker
contexts, resource names and ports; do not remove an unrelated container or
volume to make an example fit. Public example passwords are not suitable for
sensitive data. Use the [PostgreSQL guide](postgresql.md) for roles and remote
access, and [operations](operations.md) for recovery.

## 1. Choose only what is needed

| Service | Default port | Add it when |
|---|---:|---|
| PostgreSQL | 5432 | Relational application data is required |
| Redis | 6379 | A cache, queue, session store, or pub/sub service is required |
| MongoDB | 27017 | A project explicitly uses MongoDB |

Do not start all services “just in case.” A repository-owned `compose.yaml` is
preferable when the service belongs to one project. The commands below provide
a simple machine-level development service without requiring Docker Compose.

## 2. choose Docker Desktop or OrbStack

Keep an approved existing installation. If neither is installed, choose one:

```bash
# Docker Desktop:
brew install --cask docker-desktop
open -a Docker
# Or OrbStack:
brew install --cask orbstack
open -a OrbStack
```

Company Portal or the provider's signed installer is also suitable. Finish
first-run permission/licence prompts and wait for the engine to start. Installing
an app bundle alone does not prove the CLI or server works.

If `docker` is missing from PATH, use the matching bundled location for this
Terminal window:

```bash
# Docker Desktop user CLI install:
export PATH="$HOME/.docker/bin:$PATH"
# Or OrbStack:
export PATH="$HOME/.orbstack/bin:$PATH"
```

Docker Desktop also bundles its CLI in
`/Applications/Docker.app/Contents/Resources/bin`. In its settings choose the
system or user CLI installation location. Save the matching PATH export via
your selected shell configuration owner if your login shell does not already load it.
Day One Mac discovers these locations for its own container commands without
creating competing CLI symlinks. See [Docker's Mac CLI installation guidance](https://docs.docker.com/desktop/setup/install/mac-permission-requirements/).

Verify the command and the engine separately:

```bash
docker --version
docker version
docker info
docker context show
```

Both **Client** and **Server** must appear. An installed CLI with no server is
incomplete. Continue with the same chosen context for all commands below;
containers and named volumes belong to that engine.

## 3. create a shared development network

```bash
docker network inspect dev-net >/dev/null 2>&1 || \
  docker network create dev-net
```

This makes later project containers able to reach a database by container name
without exposing additional internal ports.

## 4. PostgreSQL option

This uses `postgres` for the username, password and default database in a
disposable local container, with persistence and a health check:

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

These fixed credentials permit only synthetic disposable local data. Do not
use this container for sensitive or retained data, or reuse its credentials in
a deployed environment.

Verify:

```bash
docker inspect --format='{{.State.Health.Status}}' dev-postgres
docker exec dev-postgres psql -U postgres -d postgres -c 'select version();'
```

Connection URL from macOS:

```text
postgresql://postgres:postgres@localhost:5432/postgres
```

## 5. Redis option

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

## 6. MongoDB option

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

Choose [DataGrip](datagrip.md), [DBeaver](dbeaver.md) or [VS Code](vscode.md).
Install one approved client and complete its connection test. Clients do not
create or share the server automatically.

## 7. Daily lifecycle commands

```bash
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
docker stop dev-postgres dev-redis dev-mongo    # name only those installed
docker start dev-postgres dev-redis dev-mongo
docker logs --tail 100 dev-postgres
docker stats --no-stream
```

Stopping a container keeps its named volume. Removing a container also keeps
the volume unless the volume is explicitly deleted.

## 8. Back up before destructive work

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

## 9. Remove safely

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
volumes. See [Upgrade notes](../../../shared/upgrade-notes.md) only when an
existing automation still uses an earlier flag name.

## Verify and troubleshoot

Expected result: the intended local context contains only the selected services,
health checks pass, and ports bind to loopback. A running process alone is not a
healthy database. Open one selected client and run a harmless version query.

| Symptom | Action |
|---|---|
| No Docker server | Start the selected engine and complete its first-run prompts |
| Name or port already exists | Identify its owner; choose a separate project resource rather than deleting it |
| Container is unhealthy | Inspect that container's logs locally and its version/configuration |
| Client cannot connect | Check the published host port and database role before changing network exposure |

Keep volumes until their backup and disposal decision is explicit. Continue to
[PostgreSQL roles and client setup](postgresql.md).
