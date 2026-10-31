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

## 2. Choose Docker Desktop or OrbStack

Keep an approved existing installation. If neither is installed, choose one:

For Docker Desktop only:

```bash
brew install --cask docker-desktop
open -a Docker
```

For OrbStack instead:

```bash
brew install --cask orbstack
open -a OrbStack
```

Company Portal or the provider's signed installer is also suitable. Finish
first-run permission/licence prompts and wait for the engine to start. Installing
an app bundle alone does not prove the CLI or server works.

If `docker` is missing from PATH, use the matching bundled location for this
Terminal window:

For Docker Desktop's user CLI installation:

```bash
export PATH="$HOME/.docker/bin:$PATH"
```

For OrbStack instead:

```bash
export PATH="$HOME/.orbstack/bin:$PATH"
```

Docker Desktop also bundles its CLI in
`/Applications/Docker.app/Contents/Resources/bin`. In its settings choose the
system or user CLI installation location. Save the matching PATH export via
your selected shell configuration owner if your login shell does not already load it.
See [Docker's Mac CLI installation guidance](https://docs.docker.com/desktop/setup/install/mac-permission-requirements/).

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

## 3. Create a shared development network

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

For PostgreSQL, follow the canonical [backup and separate-target restore](operations.md#3-back-up-and-rehearse-a-restore).
It checks the dump command, archive contents and restored data. Use the examples
below only for the disposable Redis and MongoDB services created on this page.
Pause application writes during each backup. Production recovery needs the
service owner's consistency, retention and access policy.

### Redis snapshot and isolated restore

1. Create a private backup directory:

   ```bash
   umask 077
   mkdir -p "$HOME/Backups/databases"
   redis_backup="$(mktemp -d "$HOME/Backups/databases/redis.XXXXXX")"
   redis_test="restore-redis-${redis_backup##*.}"
   ```

   Expected result: a new directory and unique test-container name.

2. Export a snapshot, then copy it out only if export succeeds:

   ```bash
   docker exec dev-redis redis-cli --rdb "/tmp/$redis_test.rdb" &&
     docker cp "dev-redis:/tmp/$redis_test.rdb" "$redis_backup/dump.rdb"
   ```

   Expected result: successful transfer and a non-empty RDB file. Check with
   `test -s "$redis_backup/dump.rdb"`. Stop on error; a file's presence alone
   is not verification. See the [Redis CLI backup command](https://redis.io/docs/latest/develop/tools/cli/#remote-backups-of-rdb-files)
   and [RDB snapshots and recovery](https://redis.io/docs/latest/operate/oss_and_stack/management/persistence/).

3. Prepare a separate container using the source image, with no network:

   ```bash
   redis_image="$(docker inspect --format '{{.Image}}' dev-redis)"
   docker create --name "$redis_test" --network none "$redis_image" \
     redis-server --appendonly no --save ''
   docker cp "$redis_backup/dump.rdb" "$redis_test:/data/dump.rdb"
   docker start "$redis_test"
   ```

   Run each line only after the previous one succeeds. Expected result: an
   isolated Redis instance reads the copied RDB. AOF is disabled for this
   rehearsal so an existing append-only log cannot take precedence over it.

4. After startup, compare database counts and selected non-sensitive values:

   ```bash
   docker exec dev-redis redis-cli INFO keyspace
   docker exec "$redis_test" redis-cli INFO keyspace
   docker exec "$redis_test" redis-cli ping
   ```

   Expected result: `PONG` and expected data. Expiring keys can change counts;
   verify representative values and TTLs as well. Keep the original untouched.

### MongoDB archive and isolated restore

1. Create a new private backup directory:

   ```bash
   umask 077
   mkdir -p "$HOME/Backups/databases"
   mongo_backup="$(mktemp -d "$HOME/Backups/databases/mongo.XXXXXX")"
   mongo_test="restore-mongo-${mongo_backup##*.}"
   ```

   Expected result: a unique path. The following credentials are solely for
   this page's synthetic local example; never substitute production credentials
   into command text.

2. Export the local databases:

   ```bash
   if docker exec dev-mongo mongodump --username dev --password dev \
     --authenticationDatabase admin --archive --gzip > "$mongo_backup/local.archive.gz"; then
     printf 'Archive completed: %s\n' "$mongo_backup/local.archive.gz"
   else
     printf 'Backup failed; do not restore the partial archive\n' >&2
   fi
   ```

   Expected result: successful completion and a non-empty archive. See the
   [MongoDB archive options](https://www.mongodb.com/docs/database-tools/mongodump/). Keep writers
   paused; this standalone example does not provide a cross-collection snapshot
   of a live changing application.

3. Start a separate instance from the same image, without a network:

   ```bash
   mongo_image="$(docker inspect --format '{{.Image}}' dev-mongo)"
   docker run -d --name "$mongo_test" --network none "$mongo_image"
   ```

   Expected result: a new isolated instance. Wait until
   `docker exec "$mongo_test" mongosh --quiet --eval 'db.runCommand({ping:1})'`
   reports `ok: 1`. This test instance has no network and uses no authentication.

4. Restore into that fresh instance:

   ```bash
   docker exec -i "$mongo_test" mongorestore --archive --gzip --stopOnError \
     < "$mongo_backup/local.archive.gz"
   ```

   Expected result: zero failed documents and exit status 0. Compare collection
   counts, indexes and representative records with the paused source using
   `mongosh`. Validate application behaviour before calling the backup usable.
   See [MongoDB restore requirements](https://www.mongodb.com/docs/database-tools/mongorestore/).

### Retention and test cleanup

Copy verified backups to an encrypted external volume or approved remote store.
`~/Backups` is still on the Mac's own drive. A named volume alone cannot recover
from loss of the Mac.

Inspect `docker ps -a` and the exact test name before removal. After confirming
its data is disposable, run only the selected command:

```bash
# These variables must still identify this session's separate restore test.
docker rm -v -f "$redis_test"
# Or:
docker rm -v -f "$mongo_test"
```

Expected result: that test container and its anonymous volumes are removed.
The source container and host backup remain. If a restore fails, preserve the
test container and logs until the cause is understood; do not modify the source
volume to make the rehearsal pass.

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

The retired Day One Mac cleanup command is not available. Keep container data
and independent backups until the exact resource owner approves disposal.

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
