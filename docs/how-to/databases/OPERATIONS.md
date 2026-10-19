# PostgreSQL migrations, verification and recovery

**Document type:** operational how-to. **Source verification:** 15 October 2026.

Complete the [PostgreSQL foundation](POSTGRESQL.md) first. These procedures apply independently of the chosen client. Keep personal browsing, application runtime and migration identities separate. [Database guide index](README.md).

## 9. Configure applications and promote migrations

### Give the application its own connection

Use `app_local_runtime` for the local exercise's application connection. The
developer/reader GUI logins remain separate. Configure the application's schema
as `app` using its framework's supported mechanism, or use qualified names.
The tutorial's table alone does not constitute a real application's schema.

A **placeholder template**, not a working secret, might look like:

```dotenv
DATABASE_URL=postgresql://<runtime-user>:<url-encoded-password>@<host>:<port>/<database>
```

Use your application's existing variable names and loading mechanism. Put real
local values only in its ignored private environment file or approved secret
injection flow. Before adding secrets, confirm the file is ignored, for example
`git check-ignore -- .env.local`; no output means the ignore rule needs review.
An ignore rule does not protect a file already tracked by Git. Keep example
files credential-free and never put production credentials in frontend code.

Hosted environments should receive independent runtime and migration secrets
from the deployment platform. Configure verified TLS using the actual driver's
options and trusted CA. Do not assume DataGrip's JDBC properties are valid in a
Node, Python or Prisma connection string. Restart/reload the application using
its documented procedure after rotating a secret; each GUI client must also
refresh its own credentials.

### Promote schema changes in order

1. On a feature branch, edit the schema and generate a migration using the
   repository's pinned tools. Read the generated SQL and identify table rewrites,
   locks, data loss, downtime and compatibility with the running application.
2. Apply to local synthetic data. Verify both the migration identity and the
   restricted runtime identity; test the application, not only a GUI query.
3. Commit the reviewed migration and promote the **same artifact** to shared
   development, then isolated CI/test. Exercise forward upgrade from the prior
   release, clean installation and application rollback compatibility.
4. Before production, confirm backup/restore readiness, expected duration, lock
   limits, monitoring, approval and recovery owner. Prefer compatible staged
   changes when old and new application versions overlap.
5. Deploy through the restricted migration job, verify its result, then run the
   application smoke checks and inspect errors/latency. Retire temporary access.

For Prisma or another ORM, use the repository's documented development and
deployment commands for its installed version. A development reset or shadow
database must never target shared test or production. Use a separate disposable
shadow database if required. A schema diff produced by DataGrip is a review
input, not authorization to apply it directly to production.

## 10. Use and verify connections safely

### Identify the actual session

Run this in either client before significant work:

```sql
SELECT current_database() AS database_name,
       session_user AS login_role,
       current_user AS effective_role,
       inet_server_addr() AS server_address,
       inet_server_port() AS server_port,
       current_setting('server_version') AS server_version,
       current_setting('transaction_read_only') AS transaction_read_only;
SHOW search_path;
SELECT ssl, version, cipher
FROM pg_stat_ssl
WHERE pid = pg_backend_pid();
```

For the direct loopback exercise, SSL is false. Remote TLS connections should
show SSL true. This shows transport encryption on the database session; it does
**not** prove client-side CA/hostname validation. Check each client's settings
as well. A pooler/proxy may expose different backend addresses or TLS details;
the service owner must confirm the complete path.

### Check the local reader without attempting a write

Connect as `app_local_reader`, then run:

```sql
SELECT has_schema_privilege(current_user, 'app', 'CREATE') AS can_create,
       has_table_privilege(current_user, 'app.setup_check', 'SELECT') AS can_read,
       has_table_privilege(current_user, 'app.setup_check', 'INSERT') AS can_insert,
       has_table_privilege(current_user, 'app.setup_check', 'UPDATE') AS can_update,
       has_table_privilege(current_user, 'app.setup_check', 'DELETE') AS can_delete;
SELECT rolsuper, rolcreatedb, rolcreaterole, rolbypassrls
FROM pg_roles WHERE rolname = current_user;
```

Expect `false, true, false, false, false` in the first result and all false in
the second. These checks cover the tutorial objects only. For production, the
DBA must review memberships, ownership, all accessible schemas, functions and
row-level policies. Test denied operations in an isolated test environment;
do not probe production with potentially destructive statements.
[PostgreSQL privilege inquiry functions](https://www.postgresql.org/docs/17/functions-info.html),
[statistics views](https://www.postgresql.org/docs/17/monitoring-stats.html).

### Bound interactive work

Select columns explicitly, filter early and limit returned rows. A `LIMIT` does
not guarantee a cheap query: joins and sorts can still scan large datasets.
Use the team's query limits. For an ordinary diagnostic session, illustrative
starting values are:

```sql
SET statement_timeout = '30s';
SET lock_timeout = '3s';
SET idle_in_transaction_session_timeout = '60s';
```

These are per-session examples, not universal migration limits or a permission
boundary. Clients can open more than one session. Have the DBA configure
appropriate role/database defaults where consistency is required. Review plans
before expensive work; `EXPLAIN ANALYZE` actually executes the query. Close idle
consoles and never leave an uncommitted transaction open while changing tasks.
[PostgreSQL client defaults](https://www.postgresql.org/docs/17/runtime-config-client.html),
[EXPLAIN](https://www.postgresql.org/docs/17/sql-explain.html).

## 11. Back up and rehearse a restore

### Local tutorial: back up one database

This recipe is for the disposable `dev-postgres` example only. It uses the
container's matching PostgreSQL tools and does not require a host installation.
Run it in Terminal; retain the printed path for the next step:

```bash
umask 077
mkdir -p "$HOME/Backups/databases"
db_backup_dir="$(mktemp -d "$HOME/Backups/databases/app-local.XXXXXX")"
if docker exec dev-postgres pg_dump -U postgres -d app_local -Fc \
  > "$db_backup_dir/app_local.dump"; then
  printf 'Dump completed: %s\n' "$db_backup_dir/app_local.dump"
else
  printf 'Dump failed; do not use the partial file in %s\n' "$db_backup_dir" >&2
fi
```

Continue only after success. Inspect the archive's object list:

```bash
docker exec -i dev-postgres pg_restore --list < "$db_backup_dir/app_local.dump"
```

A logical database dump does not include cluster roles; preserve the reviewed
role/provisioning definitions separately. Use the matching server-major client
tools for predictable behaviour. Dumps contain database contents and need the
same access protection as those contents.
[PostgreSQL pg_dump](https://www.postgresql.org/docs/17/app-pgdump.html).

### Restore to a new local target

Inspect `docker exec dev-postgres psql -U postgres -d postgres -c '\l'` first.
Confirm that `app_local_restore_check` does not exist and that you are using the
local tutorial container. The next commands create a separate database and do
not overwrite `app_local`. Run them one at a time, proceeding only on success:

```bash
docker exec dev-postgres createdb -U postgres -O app_local_owner app_local_restore_check
docker exec -i dev-postgres pg_restore -U postgres \
  -d app_local_restore_check --exit-on-error < "$db_backup_dir/app_local.dump"
docker exec dev-postgres psql -U postgres -d app_local_restore_check \
  -c 'SELECT id, note FROM app.setup_check ORDER BY id;'
```

This same-cluster rehearsal already has the source roles. A separate server
needs those roles or a reviewed ownership/grant remapping first. Check object
ownership, permissions, expected data and application behaviour; a non-empty
file or successful object listing alone does not prove a usable backup. Keep
the restore target until verification is complete. Any later removal requires
checking its exact name and confirming it is disposable.
[PostgreSQL pg_restore](https://www.postgresql.org/docs/17/app-pgrestore.html).

The new target database also needs its own database-level connection grants;
restoring objects into a pre-created database is not a complete access-policy
restore. For this exercise, have the local administrator revoke public access
and grant the three tutorial logins access to that target:

```sql
REVOKE ALL ON DATABASE app_local_restore_check FROM PUBLIC;
GRANT CONNECT ON DATABASE app_local_restore_check
  TO app_local_dev, app_local_runtime, app_local_reader;
```

Run that SQL in the local administration session, then repeat the reader checks
against a new connection explicitly targeting `app_local_restore_check`.

`~/Backups` is on the Mac's own disk. Copy needed backups to an encrypted
external volume or approved remote destination. A named container volume is
persistence, not protection against loss of the Mac.

### Shared and production recovery

Use the service owner's scheduled backup/PITR process and retention policy.
Rehearse recovery into an isolated target, measure achieved RPO/RTO, verify
identities and application health, and document the cutover procedure.
Client connection exports and DataGrip project backups are not database backups.
Do not restore production data onto a developer Mac or shared test service
without explicit data-owner approval and the required sanitization/access controls.
