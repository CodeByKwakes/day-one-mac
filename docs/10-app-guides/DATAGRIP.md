[← Application guides](README.md) · [Local database module](../02-optional/09-databases.md) · [VS Code profiles](VSCODE-PROFILES.md)

# PostgreSQL setup with DataGrip and VS Code

**Document type:** setup tutorial, followed by operational how-to recipes and
reference checklists. **Audience:** developers and administrators using a
personal or managed Apple-silicon Mac. **Last source check:** 15 October 2026.

Use this guide to create a disposable local PostgreSQL database, connect to it
from DataGrip and VS Code, and prepare separate development, test and production
connections. Hosting is deliberately provider-neutral. Your database owner
must supply the remote infrastructure, authentication and recovery details.

DataGrip is a database **client**; installing it does not install PostgreSQL.
VS Code is another client of the same server. Neither client automatically
copies the other's connections, passwords, certificates or SSH tunnels. Your
application makes a third, independent connection using its own identity.

For a free desktop alternative, follow the [DBeaver Community guide](DBEAVER.md).
Its setup reuses this guide's local server, role, migration and restore procedures;
those Terminal/SQL sections work without installing DataGrip. Do not create a
second database or rerun role creation just to add another client.

DataGrip is optional and is not installed or configured by Day One Mac's
application catalogue. Database access is a shared manual action on both setup
routes. Module 09 provisions only the selected local containers; it does not
provision remote environments or apply your application's migrations.

## Contents

1. [Plan environments and access](#1-plan-environments-and-access)
2. [Install DataGrip and prepare the clients](#2-install-datagrip-and-prepare-the-clients)
3. [Start a local PostgreSQL server](#3-start-a-local-postgresql-server)
4. [Create a local example database and roles](#4-create-a-local-example-database-and-roles)
5. [Connect DataGrip to local PostgreSQL](#5-connect-datagrip-to-local-postgresql)
6. [Prepare shared development, test and production](#6-prepare-shared-development-test-and-production)
7. [Connect DataGrip to remote environments](#7-connect-datagrip-to-remote-environments)
8. [Connect VS Code to the same databases](#8-connect-vs-code-to-the-same-databases)
9. [Configure applications and promote migrations](#9-configure-applications-and-promote-migrations)
10. [Use and verify connections safely](#10-use-and-verify-connections-safely)
11. [Back up and rehearse a restore](#11-back-up-and-rehearse-a-restore)
12. [Optional SQL handoff and AI access](#12-optional-sql-handoff-and-ai-access)
13. [Troubleshoot and maintain the setup](#13-troubleshoot-and-maintain-the-setup)
14. [Completion checklists and source references](#14-completion-checklists-and-source-references)

## 1. Plan environments and access

### Choose the boundary for each environment

The following names and colours are this guide's convention. Names help people
recognize context; database permissions and network controls enforce access.

| Environment | Purpose and data | Suggested connection | Normal human access |
|---|---|---|---|
| Local | Disposable synthetic data on this Mac | `LOCAL • app • developer` — blue | Developer owns only the example application's objects |
| Development | Shared integration work; synthetic or approved sanitized data | `DEV • app • developer` — green | Named developer role; schema changes through migrations |
| Test | Repeatable CI, QA and release verification | `TEST • app • reader` — amber | Reader initially; separate test writer for approved work |
| Production | Live service and real data | `PROD • app • READ ONLY` — red | Named, database-enforced reader restricted to needed data |
| Production maintenance | Approved change or incident work | `PROD • app • MAINTENANCE` — red | Separate, time-bounded maintenance identity |

Keep production on a separate service or cluster with independent access and
secrets. Separate database names on one server are useful organization, but
share administration, resources and a failure boundary. Roles are defined for
the whole PostgreSQL cluster, so include the application/environment in role
names where environments share a cluster.
[PostgreSQL role scope](https://www.postgresql.org/docs/17/sql-createrole.html).

Use individual identities for humans and separate service identities for the
application, CI and migrations. In particular, do not use the application's
production password for browsing in either editor.

### Complete a private connection worksheet

Record one row per connection in an approved private location. The repository
should contain only blank templates and synthetic examples. Retrieve secrets
from the approved secret manager when needed; do not put passwords in this
worksheet, screenshots or support tickets.

| Field | What to obtain or decide |
|---|---|
| Owner and purpose | Service owner, environment, permitted tasks and support contact |
| Server | PostgreSQL major version, hostname, port, database and application schema |
| Endpoint type | Direct, pooler or read replica; provider's supported client behaviour |
| Identity | Personal role or service role, authentication method, expiry and renewal |
| Network | Private DNS, VPN or approved bastion, allowed source network and port |
| TLS | Certificate hostname, trusted CA bundle, rotation owner; client certificate only if required |
| Permissions | Read, application DML, migration DDL or temporary administration |
| Recovery | Backup owner, retention, restore procedure, RPO and RTO |

RPO is the maximum acceptable loss of recent data; RTO is the target time to
restore service. Choose these with the service owner before production use.
An Azure DevOps repository does not imply that its database is hosted on Azure.

## 2. Install DataGrip and prepare the clients

1. On a managed Mac, use the company portal or approved installation method.
   Keep an existing managed installation under its current owner.
2. On a personal Mac, use JetBrains Toolbox or the official DataGrip disk image.
   Choose the Apple-silicon build and a supported stable version. For the disk
   image route, drag the app into Applications and open it.
3. Complete first launch and the applicable licence/account flow. Do not import
   an old bundle of production connections before reviewing its contents.
4. Create a local DataGrip project for development. Keep production work in a
   separate project for clarity; this is not a security isolation mechanism.
   Keep private connection metadata and query history outside public Git repos.
5. In DataGrip Settings, search for **Passwords**. Use **In native Keychain**
   where policy permits, or choose not to save passwords. Enter credentials in
   the password field, never in a JDBC URL: URL-only connections can expose the
   literal URL in configuration and logs.

[JetBrains installation](https://www.jetbrains.com/help/datagrip/installation-guide.html)
and [password storage](https://www.jetbrains.com/help/datagrip/reference-ide-settings-password-safe.html).

Complete [VS Code base setup](VSCODE.md). If using the project profiles, select
Full Stack for development and Operations for production investigation in the
[profile guide](VSCODE-PROFILES.md). These profiles organize tools; they do not
isolate saved credentials. Install the PostgreSQL extension in section 8.

No separate PostgreSQL server, Java installation or Homebrew database service
is required merely to connect DataGrip to an existing server. The local
tutorial uses the PostgreSQL tools already inside its container.

## 3. Start a local PostgreSQL server

### First choose who owns the local service

| Situation | Route |
|---|---|
| The application already supplies `compose.yaml` | Use its documented container, schema, seed and migration commands |
| You want a machine-level disposable PostgreSQL sandbox | Choose one of the Module 09 routes below |
| You need sensitive or retained local data | Use a separately managed service with unique credentials and an approved backup/access design |

Check for an existing listener before creating another service:

```bash
lsof -nP -iTCP:5432 -sTCP:LISTEN
```

No output means no listener was found at that moment. If occupied, identify its
owner; do not stop or delete it to make this tutorial fit. A project-owned
container can publish another loopback port, such as `127.0.0.1:5433:5432`.
Use that port in both clients. Module 09's service uses its fixed port 5432.

### Script-assisted route

Complete required Phase 8 first. Preview only PostgreSQL, then apply the
reviewed plan if disposable synthetic data is appropriate:

```bash
day-one-mac optional --module 09 --plan --services postgres
day-one-mac optional --module 09 --apply --services postgres --disposable-data
day-one-mac databases --saved --status
```

The current module uses `postgres:17-alpine`, records its resolved image digest,
binds PostgreSQL to `127.0.0.1:5432`, and creates `dev-postgres` with volume
`dev-pgdata`. It limits the service to 2 GiB/2 CPUs and disables automatic
restart. Its bootstrap username, password and database are all `postgres`.
These public fixed credentials permit **synthetic disposable data only**.

### Manual route

Follow [Module 09's manual container-engine, network and PostgreSQL steps](../02-optional/09-databases.md#step-92--manual-path-choose-docker-desktop-or-orbstack)
without invoking Day One Mac. Review the existing resource names first. The
manual example uses the same local connection values, but its restart and
ownership settings differ from the assisted route. Do not run both routes for
the same containers or expect the assisted installer to adopt a manual service.

### Shared manual verification

For the Module 09 container, check the selected local Docker context and health:

```bash
docker context show
docker inspect --format='{{.State.Health.Status}}' dev-postgres
docker port dev-postgres 5432
docker exec dev-postgres psql -U postgres -d postgres -c 'select version();'
```

Expect `healthy`, a `127.0.0.1:5432` mapping and PostgreSQL 17. For a
repository-owned container, substitute its documented name and port. A GUI
client on macOS uses the published host address; a containerized application
uses the database service name and container port on its shared network.

Match your actual project's PostgreSQL major version, extensions and locale
requirements across local/dev/test/prod. This tutorial follows Module 09's
version; it is not a recommendation to change an existing production version.

## 4. Create a local example database and roles

This optional exercise makes a new `app_local` database with an `app` schema.
Skip it for an existing application and run that repository's migrations
instead. Do not run these bootstrap statements on shared or production servers.
Adding individual roles does not make the fixed-credential container suitable
for sensitive data: its bootstrap superuser still exists.

### Open the local administration session

```bash
docker exec -it dev-postgres psql -X -U postgres -d postgres
```

Inside `psql`, inspect existing databases and roles:

```text
\l
\du
```

Proceed only if `app_local` and the four role names below are unused. The
example is a one-time setup, not an idempotent migration. If any statement
fails, stop and inspect the partial result; do not drop existing objects or
continue blindly. PostgreSQL passwords are set with interactive `\password`
prompts, avoiding literal passwords in saved SQL.
[Role creation](https://www.postgresql.org/docs/17/sql-createrole.html),
[psql commands](https://www.postgresql.org/docs/17/app-psql.html).

Run this SQL in the local `psql` session:

```sql
CREATE ROLE app_local_owner NOLOGIN;
CREATE ROLE app_local_dev LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE
  NOREPLICATION NOBYPASSRLS IN ROLE app_local_owner;
CREATE ROLE app_local_runtime LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE
  NOREPLICATION NOBYPASSRLS;
CREATE ROLE app_local_reader LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE
  NOREPLICATION NOBYPASSRLS;

CREATE DATABASE app_local OWNER app_local_owner;
REVOKE ALL ON DATABASE app_local FROM PUBLIC;
GRANT CONNECT ON DATABASE app_local
  TO app_local_dev, app_local_runtime, app_local_reader;
```

Run each command below individually. Finish both password prompts before
entering the next command. Use three different generated passwords and save
them in your approved private password manager:

```text
\password app_local_dev
\password app_local_runtime
\password app_local_reader
\connect app_local
```

Run the following SQL after confirming the prompt now names `app_local`:

```sql
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
CREATE SCHEMA app AUTHORIZATION app_local_owner;
GRANT USAGE ON SCHEMA app TO app_local_runtime, app_local_reader;

SET ROLE app_local_owner;
ALTER DEFAULT PRIVILEGES IN SCHEMA app
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_local_runtime;
ALTER DEFAULT PRIVILEGES IN SCHEMA app
  GRANT USAGE, SELECT ON SEQUENCES TO app_local_runtime;
ALTER DEFAULT PRIVILEGES IN SCHEMA app
  GRANT SELECT ON TABLES TO app_local_reader;
ALTER DEFAULT PRIVILEGES REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;

CREATE TABLE app.setup_check (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  note text NOT NULL
);
INSERT INTO app.setup_check (note) VALUES ('Synthetic local setup check');
RESET ROLE;
```

Exit with `\q`. The developer can manage the local application schema; the
runtime role can change table data and use its identity sequence; the reader
can select table data. The latter two have no owner-role membership.

Default privileges apply only to **future objects created by the named/current
owner**. Use `SET ROLE app_local_owner` before local schema creation. Creating
tables as `postgres` or directly as `app_local_dev` does not use the owner's
defaults. Existing objects need explicit grants. This example also removes
default public execution of future application functions; grant execution only
where an application needs it.
[Default privileges](https://www.postgresql.org/docs/17/sql-alterdefaultprivileges.html).

For an existing application, adapt schema ownership and grants through reviewed
migrations. For example, an authorized owner can grant reader access to existing
tables with `GRANT SELECT ON ALL TABLES IN SCHEMA app TO app_local_reader;`.
Do not apply broad grants to a production schema containing data that the reader
should not see; use approved views or narrower grants.
[PostgreSQL grants](https://www.postgresql.org/docs/17/sql-grant.html).

## 5. Connect DataGrip to local PostgreSQL

1. Open **File → New → Data Source → PostgreSQL**.
2. Keep the standard PostgreSQL driver; use **Download missing driver files**
   if offered and permitted by your network policy.
3. Fill in the fields below. Use the password field, not a credential-bearing URL.
4. Select **Test Connection**, then save the data source.
5. On **Schemas**, select `app` for this exercise; introspect only needed schemas.

| Field | Local exercise value |
|---|---|
| Name | `LOCAL • app • developer` |
| Host / port | `127.0.0.1` / `5432` |
| Database | `app_local` |
| Authentication / user | User & Password / `app_local_dev` |
| Password | The value you entered interactively |
| SSH / SSL | No SSH; SSL disabled only for this loopback disposable container |

[DataGrip PostgreSQL connection procedure](https://www.jetbrains.com/help/datagrip/postgresql.html).

Open a query console attached to that data source and run:

```sql
SELECT current_database(), current_user;
SELECT id, note FROM app.setup_check ORDER BY id LIMIT 10;
```

Expect `app_local`, `app_local_dev` and the synthetic row. Add a second
connection named `LOCAL • app • reader` using `app_local_reader`. Run the same
queries there, then the privilege checks in section 10. This demonstrates the
two access levels without changing real data.

If you skipped section 4, use your repository's database and individual role.
The Module 09 bootstrap connection is database/user/password `postgres`; reserve
it for the disposable sandbox's administration, not the application connection.

## 6. Prepare shared development, test and production

These steps belong to the database/platform owner. If you are connecting as a
developer, request the completed worksheet and begin section 7. Because the
hosting provider is undecided, there is no assumed cloud portal or universal
server-creation command.

### Provision the service before configuring either client

1. **Select the supported service and version.** Record region, engine major
   version, extensions, encoding/collation requirements, sizing and owner.
   Provision using the team's reviewed infrastructure configuration or approved
   provider workflow. Keep production access and resources separate.
2. **Establish private connectivity.** Configure private DNS and the approved
   VPN/bastion route. Restrict incoming database traffic to required application,
   migration and human access paths. Do not open port 5432 to the whole internet
   to resolve a connection problem.
3. **Enable and verify TLS.** Publish the hostname and approved CA instructions.
   For a self-hosted service, the administrator also owns server certificates,
   listening addresses, firewall and host-based authentication rules. Managed
   services expose these through provider controls; do not assume filesystem
   access to `postgresql.conf` or `pg_hba.conf`.
4. **Create the database, schemas and identities.** Use an authorized bootstrap
   administrator. Separate object ownership from application logins, humans and
   CI. Record precisely which identity creates migration objects so existing
   and future grants agree.
5. **Configure operational controls.** Establish patching, encrypted storage,
   backups, restore retention, high availability where needed, connection limits
   and alerts for storage, query latency, locks and failed access. Agree an
   incident owner and credential rotation process.
6. **Apply reviewed migrations and permitted seed data.** Give applications only
   the data permissions they need. Give migration jobs the scoped DDL privileges
   needed by the chosen framework, rather than the server administrator login.
7. **Verify using each actual identity.** Test networking, TLS, database name,
   migrations, application operations and reader privileges. Test a restore to
   an isolated target before declaring production recovery ready.

### Environment-specific provisioning decisions

| Control | Development | Test | Production |
|---|---|---|---|
| Database example | `app_dev` | `app_test` or isolated DB per test run | `app_prod` |
| Schema/version | Matches application migrations | Rebuilt from release candidate | Only approved migration revision |
| Data | Synthetic or approved sanitized fixtures | Deterministic fixtures; no unrestricted production copies | Governed live data |
| Application identity | Dev-only runtime role | Test-only runtime role | Production-only runtime role |
| Migration identity | Dev migration owner | CI migration owner | Restricted deployment identity |
| Human identity | Named developer; agreed write scope | Reader; separate QA writer if needed | Named restricted reader; temporary maintenance separately |
| Reset policy | Explicit agreement before reset | Only the current run's isolated resources | No development reset commands |
| Recovery | Retained if shared work matters | Rebuild fixtures; retain necessary evidence | Defined RPO/RTO and successful restore rehearsal |

Do not reuse section 4's role names or password flow as a production policy.
Use organization-approved group membership and authentication. Readers must not
own objects, inherit writer/owner roles, have `BYPASSRLS`, or execute application
functions that can change data. Restrict sensitive columns/tables through views,
grants or the application's approved row-level policies. A `read_only` session
setting alone is not a grant boundary.

## 7. Connect DataGrip to remote environments

Create a **new data source per environment and access level**. Use the same
PostgreSQL driver procedure as section 5, substituting the worksheet's actual
host, port, database, role and authentication. If duplicating a data source,
clear the copied password and verify every field before the first connection.

### Configure transport and credentials

1. Connect the approved VPN if required; confirm private DNS works.
2. In **SSH/SSL**, enable SSL and choose **Full Verification** with the trusted
   CA file or approved truststore. Use the certificate's DNS hostname. Configure
   a client certificate/key only when the service requires mutual TLS.
3. For a bastion route, enable **Use SSH tunnel** and add the approved SSH host,
   user and authentication. Prefer the existing approved authentication agent
   where supported. Verify a new SSH host key against the owner's fingerprint.
   The database host is the address reachable from the bastion, not the bastion
   itself; keep the database's TLS hostname verification valid.
4. Test the connection and run section 10's context checks. If TLS fails, correct
   the hostname, certificate chain or tunnel configuration. Do not disable
   verification as a permanent fix. Ask the owner for a supported route if the
   selected tunnel cannot preserve certificate verification.

An SSH tunnel encrypts traffic to its SSH endpoint; it does not by itself prove
the identity of a separate database server beyond that endpoint.
[DataGrip SSH and SSL](https://www.jetbrains.com/help/datagrip/configuring-ssh-and-ssl.html),
[PostgreSQL TLS verification](https://www.postgresql.org/docs/17/libpq-ssl.html).

Use the hosting provider's supported token/SSO procedure when applicable.
Authentication choices and token renewal can differ between DataGrip and VS
Code. Do not replace an approved short-lived identity with a permanent password
merely to make both clients look alike.

### Set production defaults deliberately

In **Data Sources and Drivers → Options**, enable **Read-only** for the normal
production connection, restrict introspection to needed schemas, and choose
auto-disconnection appropriate to your workflow. Name and colour it clearly.
Treat these UI settings as additional protection alongside the restricted
server role. Use a read replica only when replication lag and its permitted
workload are understood.

For approved maintenance, use the separate identity/connection. **Tx:Manual**
provides an explicit commit point for transactional work; it cannot undo every
operation or any already committed change. Finish or roll back the transaction
and disconnect when done. Do not enable immediate submission of grid edits for
production work.
[DataGrip connection and transaction controls](https://www.jetbrains.com/help/datagrip/configuring-database-connections.html).

## 8. Connect VS Code to the same databases

### Install the database extension

In Extensions, install **PostgreSQL** published by Microsoft, extension ID
`ms-ossdata.vscode-pgsql`. It is already included in the project's Full Stack and
Operations profile recipes. Check the active profile before installing another
copy. This extension connects to ordinary PostgreSQL as well as supported cloud
services; an Azure account is not needed for the local password connection.
[Official extension listing](https://marketplace.visualstudio.com/items?itemName=ms-ossdata.vscode-pgsql).

### Add and test a connection

1. Run **PGSQL: Add New Connection** in the Command Palette.
2. Choose **Parameters**. Enter server, authentication, user, database and the
   same friendly name used in DataGrip. Enter the password separately.
3. Open **Advanced**: set **Scope → User**, port and a recognizable application
   name. User scope keeps this definition out of the repository's workspace
   settings; review Settings Sync and profile exports separately.
4. Configure SSL and, if needed, SSH as described below.
5. Use **Test Connection**, then **Save & Connect**. Save Password is optional;
   Microsoft stores it through VS Code SecretStorage, backed by macOS Keychain.
6. Group connections by environment. Create/open a query from the intended
   connection and verify its database/user with section 10 before querying.

[Microsoft connection setup](https://learn.microsoft.com/en-us/azure/postgresql/development/vs-code-extension/connections).

| Setting | Local exercise | Shared dev/test/prod |
|---|---|---|
| Server / port | `127.0.0.1` / `5432` | Approved hostname and port |
| Database / user | `app_local` / `app_local_dev` or `app_local_reader` | Corresponding environment's database and personal identity |
| SSL | Disable only for this disposable loopback container | Verify-Full with approved CA trust |
| SSH | Off | Configure independently if required |

In **Advanced → SSL**, use **SSL root certificate mode → System** when the
approved CA is in the system trust store, or **Custom file** and its PEM CA
bundle. In **Advanced → SSH Tunnel**, enable tunnelling and enter the bastion
host, port, user and supported authentication method. Keep the main server field
as the database host reachable from that bastion. Do not depend on a transient
port opened internally by DataGrip. Verify TLS still succeeds through this route.
[Microsoft advanced connection options](https://learn.microsoft.com/en-us/azure/postgresql/development/vs-code-extension/advanced-connection-options).

For the local exercise, run `SELECT id, note FROM app.setup_check LIMIT 10;` in
both editors. Matching results plus the identity query confirm that both clients
reach the intended database. With a remote replica or pooler, confirm the
endpoint with its owner; identical labels alone are not proof.

If using Remote SSH or a Dev Container, check where the extension actually runs.
`127.0.0.1` refers to that execution environment. Establish its approved network
route and credential storage separately; never expose the local database on all
interfaces just to make a remote editor reach it.

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

## 12. Optional SQL handoff and AI access

### Open a VS Code SQL file in DataGrip

The optional `MaxPowerEngine.switch2datagrip` extension adds **Open in DataGrip**
to the editor context menu. Open the intended DataGrip project first. Usually
auto-detection is enough; if needed, set the actual app path in VS Code User
Settings, for example:

```json
{
  "switch2datagrip.dataGripPath": "/Applications/DataGrip.app"
}
```

Check the SQL file's attached data source in DataGrip before executing it. The
handoff opens a file; it does not synchronize database trees or credentials.
Reassign its default Cmd+Shift+D if it conflicts with the debugging shortcut.
[Extension documentation](https://marketplace.visualstudio.com/items?itemName=MaxPowerEngine.switch2datagrip).

### Connect an AI client only when needed

Start with synthetic local data. Before using development/test data, confirm
that its contents and metadata may be sent to the selected AI provider.

In DataGrip **Settings → Tools → MCP Server**, inspect **Exposed Tools** and
enable only the needed capabilities. Use the displayed client configuration
or Copy Config option for your client's supported transport; do not hard-code
a port from another installation. Keep the intended DataGrip project open,
restart the client, and first test listing connections. Leave execution without
confirmation disabled.
[JetBrains MCP server](https://www.jetbrains.com/help/datagrip/mcp-server.html).

Leave production outside the initial AI setup. An agent that can access other
credentials or edit a connection can exceed the permissions of one saved
reader connection. Review every tool and credential path. The PostgreSQL
extension's **Copilot access mode → Read Only** affects that integration only;
it does not control other agents or DataGrip MCP. Server-enforced grants and
approved data access remain necessary.

## 13. Troubleshoot and maintain the setup

| Symptom | Check and corrective action |
|---|---|
| Local connection refused | Confirm selected Docker engine/context, container health and published port; start only the intended stopped service |
| Port 5432 already occupied | Identify the owner; use the project's documented alternate loopback port instead of killing an unknown service |
| Remote timeout | Check VPN, DNS, private route, firewall and bastion reachability; have the owner verify the permitted source |
| Certificate failure | Check actual server hostname, CA chain, expiry and system clock; obtain the current approved CA, retaining verification |
| Password or token rejected | Confirm database role, auth method, identity/tenant if applicable and token expiry; refresh the saved credential in each client |
| SSH authentication fails | Check host fingerprint, approved agent/key availability and bastion username; database login and SSH login are separate |
| Database does not exist | Compare the exact database name with the worksheet; do not create a replacement on an unknown endpoint |
| Tables missing in the tree | Verify database/schema, schema selection and privileges, then refresh introspection; refresh cannot grant permissions |
| New migration tables are inaccessible | Check which role created them and its default privileges; apply reviewed grants to existing objects |
| Reader can modify data | Disconnect and have the DBA inspect grants, ownership, inherited roles and executable functions before continuing |
| One client works, the other fails | Compare host, port, role, TLS, CA, tunnel and execution environment field by field; connection state is independent |
| Slow queries or Mac | Limit introspection and open sessions; inspect workload/container resource use before increasing limits; tune queries with measured evidence |
| Changes appear missing | Check transaction state, database/schema and replica lag; do not repeat a write until its first outcome is understood |
| Restore fails | Keep source and archive intact; inspect first error, tool/server version, roles, extensions and target conflicts before retrying |

Update clients and drivers through their existing installation owners. Recheck
connections after credential/CA rotation and major upgrades. Do not point a new
PostgreSQL major image at an old data directory as an upgrade method; use the
project's tested upgrade or dump/restore plan. Audit unused accounts and saved
connections, close stale sessions and keep the connection worksheet current.

## 14. Completion checklists and source references

### Local workstation

- [ ] Exactly one owner/route manages each local database service.
- [ ] The database is healthy and published only on the intended loopback port.
- [ ] Fixed-credential Module 09 containers contain only synthetic disposable data.
- [ ] DataGrip and VS Code identify the same intended database and separate login.
- [ ] Reader checks pass; the application uses its own runtime role.
- [ ] Private connection data is excluded from repositories, exports and AI prompts.
- [ ] The local backup has been restored to a separate target when retention matters.

### Each shared environment

- [ ] Service owner, version, endpoint, auth and network route are recorded privately.
- [ ] Each client uses verified TLS and its own tested credential configuration.
- [ ] Human, runtime and migration access are distinct and appropriately scoped.
- [ ] Migration-created objects receive the intended ownership and future grants.
- [ ] Data use, reset policy, monitoring and incident ownership are agreed.
- [ ] Production defaults to restricted reader access; maintenance is separate.
- [ ] Production restore rehearsal meets the agreed RPO/RTO.

The linked JetBrains, Microsoft and PostgreSQL documentation is the source for
client controls and PostgreSQL semantics. The environment names, role design,
colours and operational sequence are this project's recommended working pattern,
to be adapted to the actual service and organizational policy. The walkthrough
is not evidence that a real remote environment has been provisioned or tested.

For local container behaviour, [Module 09](../02-optional/09-databases.md) and
its current implementation remain authoritative. For editor extension/profile
assignments, use [VS Code profiles](VSCODE-PROFILES.md). Recheck vendor UI labels
against the installed versions when they differ from this guide.

---

[Application guides](README.md) · [Local databases](../02-optional/09-databases.md) · [VS Code profiles](VSCODE-PROFILES.md) · [Security handbook](../manual/security.md)
