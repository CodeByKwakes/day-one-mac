# PostgreSQL setup across local, development, test and production

**Audience:** developers and Mac administrators. **Source verification:** 15 October 2026; procedures reorganized on 19 October 2026.

Start here for server ownership, environment separation and database roles. Complete shared setup once, then choose [DataGrip](DATAGRIP.md), [DBeaver Community](DBEAVER.md) or [VS Code](VSCODE.md). Client applications connect independently to the same database. [Database guide index](README.md).

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

Follow [Module 09's manual container-engine, network and PostgreSQL steps](../modules/optional/09-databases.md#step-92--manual-path-choose-docker-desktop-or-orbstack)
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

## 6. Prepare shared development, test and production

These steps belong to the database/platform owner. If you are connecting as a
developer, request the completed worksheet and follow your chosen client guide. Because the
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

Do not reuse the local bootstrap role names or password flow as a production policy.
Use organization-approved group membership and authentication. Readers must not
own objects, inherit writer/owner roles, have `BYPASSRLS`, or execute application
functions that can change data. Restrict sensitive columns/tables through views,
grants or the application's approved row-level policies. A `read_only` session
setting alone is not a grant boundary.
