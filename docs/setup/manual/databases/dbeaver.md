[← Application guides](../apps/README.md) · [Local database module](../../../shared/tools/09-databases.md) · [DataGrip alternative](datagrip.md) · [VS Code profiles](../../../shared/tools/vscode-profiles.md)

# PostgreSQL setup with DBeaver Community and VS Code

**Document type:** setup tutorial, followed by operational how-to recipes and
reference checklists. **Audience:** developers and administrators using a
personal or managed Apple-silicon Mac. **Last source check:** 15 October 2026.

Use DBeaver Community to browse PostgreSQL, run reviewed SQL and manage separate
local, development, test and production connections. This guide also connects
VS Code to the same databases and provides an optional SQL-file handoff.
Hosting remains provider-neutral; the service owner supplies remote endpoints,
identities, network access and recovery procedures.

DBeaver is a database **client**. Installing it does not install a PostgreSQL
server. DBeaver, DataGrip, VS Code and your application each make independent
connections. They do not automatically share passwords, certificates or tunnels.
You can keep both desktop clients without creating another database.

The [PostgreSQL foundation](postgresql.md) owns local service and role setup;
[database operations](operations.md) owns migration and recovery procedures.
Complete shared setup once, then follow the DBeaver steps here. Database connections are shared manual actions on both setup routes.

## Contents

1. [Choose the edition and installation route](#1-choose-the-edition-and-installation-route)
2. [Prepare a private workspace and credentials](#2-prepare-a-private-workspace-and-credentials)
3. [Reuse or create the local PostgreSQL sandbox](#3-reuse-or-create-the-local-postgresql-sandbox)
4. [Connect DBeaver to the local database](#4-connect-dbeaver-to-the-local-database)
5. [Organize local, dev, test and production](#5-organize-local-dev-test-and-production)
6. [Connect to shared dev, test and production](#6-connect-to-shared-dev-test-and-production)
7. [Connect VS Code to the same databases](#7-connect-vs-code-to-the-same-databases)
8. [Open a SQL file from VS Code in DBeaver](#8-open-a-sql-file-from-vs-code-in-dbeaver)
9. [Run queries and promote changes](#9-run-queries-and-promote-changes)
10. [Back up and rehearse recovery](#10-back-up-and-rehearse-recovery)
11. [Maintain the installation and private configuration](#11-maintain-the-installation-and-private-configuration)
12. [Troubleshoot the connection](#12-troubleshoot-the-connection)
13. [Completion checklists and references](#13-completion-checklists-and-references)

## 1. Choose the edition and installation route

DBeaver Community is a free, open-source desktop client. Choose its Apple
Silicon build. The standard distribution includes its Java runtime, so normal
installation does not require a separate JDK.
[Official downloads](https://dbeaver.io/download/).

Community supports ordinary PostgreSQL connections with TLS and SSH tunnels.
Do not assume every feature in DBeaver's combined documentation is included:
the PostgreSQL driver's built-in AWS RDS IAM and Azure AD authentication
options are marked **PRO**. If your organization requires an authentication
method unavailable in Community, agree an approved client or edition with IT;
do not replace required SSO with an unmanaged shared password.
[PostgreSQL driver and authentication options](https://dbeaver.com/docs/dbeaver/Database-driver-PostgreSQL/).

### Manual route

1. On a managed Mac, use the approved company portal or installer. Keep an
   existing installation under its current owner.
2. On a personal Mac, download the Apple Silicon disk image from the official
   site, open it and drag DBeaver into Applications. Alternatively, if Homebrew
   is your chosen owner, review and install the `dbeaver-community` cask:

   ```bash
   brew install --cask dbeaver-community
   ```

3. Open DBeaver. Keep any existing workspace; do not import old production
   connections until you have reviewed their metadata and access requirements.

Choose one installation owner. Do not install a second copy over a managed app.

## 2. Prepare a private workspace and credentials

The default macOS workspace is `~/Library/DBeaverData/workspace6`. Keep an
existing private workspace unless you need another location. To choose one,
use **File → Switch workspace → Other**, select the approved private folder
and choose **Launch**. Do not force two instances to use the same workspace.
[Workspace location and switching](https://dbeaver.com/docs/dbeaver/Workspace-Location/).

Keep DBeaver's workspace, connection configuration, query history and exports
outside public repositories and unapproved cloud synchronization. SQL results
and history can contain sensitive values even when passwords are absent.
Use reviewed SQL files in your application repository for reusable queries.

DBeaver's credential-storage features differ by edition. Its documentation
reserves the **Database connection credentials** encrypted-storage option for
Lite, Enterprise and Ultimate, and labels master-password protection **PRO**.
Community's integrated security provider does not establish that saved database
passwords have those paid-edition protections. Treat saved connection files as
sensitive; do not assume the VS Code extension's macOS Keychain behaviour also
applies to DBeaver.
[DBeaver security and storage](https://dbeaver.com/docs/dbeaver/Security/).

For this guide, leave **Save password** off for production and enter credentials
from the approved secret manager when prompted. Use your organization's
supported short-lived authentication flow where required. For local disposable
data, decide whether saving a generated developer password is acceptable under
your policy. Never place a password in a JDBC URL, task argument or SQL file.

Before shared access, complete a private
[connection worksheet](postgresql.md#1-plan-environments-and-access): endpoint,
database, schema, personal identity, authentication expiry, VPN/bastion, TLS CA,
certificate hostname, permitted work and recovery owner. Do not store secrets
in the worksheet. Request only the environments you need.

## 3. Reuse or create the local PostgreSQL sandbox

### Select the existing owner first

| Current situation | Next action |
|---|---|
| You completed the DataGrip local tutorial | Reuse `dev-postgres`, `app_local` and its existing passwords; skip creation |
| Your application has a documented Compose stack | Use that stack's database, migrations and roles; substitute its connection values below |
| You need a new disposable sandbox | Choose one Module 09 route below, then create the example roles once |
| You need retained or sensitive local data | Obtain a separately managed service with unique credentials and an approved backup design |

For a new Module 09 sandbox, check whether port 5432 is already occupied:

```bash
lsof -nP -iTCP:5432 -sTCP:LISTEN
```

Identify an existing service's owner rather than stopping it to fit this guide.
Module 09's assisted PostgreSQL service uses fixed loopback port 5432. A
project-owned stack can use another published loopback port if its owner agrees.

### Manual server route

Follow [Module 09's manual engine, network and PostgreSQL steps](containers.md).
Do not run both routes for the same service. The manual route has different
restart and ownership settings; the assisted route does not adopt it silently.

### Shared manual verification and role setup

The Module 09 sandbox uses PostgreSQL 17 in `dev-postgres`, backed by
`dev-pgdata`, at `127.0.0.1:5432`. Its public bootstrap credentials are
`postgres`/`postgres`. They permit **synthetic disposable data only**; adding
individual application roles does not remove that bootstrap superuser.

Verify the selected local engine and container:

```bash
docker context show
docker inspect --format='{{.State.Health.Status}}' dev-postgres
docker port dev-postgres 5432
docker exec dev-postgres psql -U postgres -d postgres -c 'select version();'
```

Expect `healthy`, a loopback mapping and the intended PostgreSQL major version.
For another project, use its documented container name and version. A macOS
client uses the published host port; a containerized application uses the
database service name and internal port on its shared network.

For a **new** example database, complete
[Create a local example database and roles](postgresql.md#3-create-a-local-example-database-and-roles)
in Terminal. That procedure checks existing names and sets passwords
interactively. It creates the following resources; it is a one-time exercise,
not a migration to rerun or apply remotely.

| Resource | Purpose |
|---|---|
| `app_local` / `app` | Example database and application schema |
| `app_local_owner` | Non-login owner of application objects |
| `app_local_dev` | Local developer login with membership in the owner role |
| `app_local_runtime` | Application login with scoped data-changing privileges |
| `app_local_reader` | Human reader login with scoped SELECT privileges |
| `app.setup_check` | Synthetic row for verifying both clients |

Stop if a resource already exists or a statement fails; inspect the existing
setup rather than dropping it. For a real application, use its own migrations
and role design instead of adding this example schema.

## 4. Connect DBeaver to the local database

1. Select **Database → New Database Connection**, choose **PostgreSQL** and
   continue. Use the current PostgreSQL driver, not the legacy driver.
2. Enter the local values below. Enter the generated developer password in its
   password field; do not use the bootstrap superuser for everyday work.
3. Select **Test Connection**. If prompted for the JDBC driver, use DBeaver's
   configured official driver source or the company-approved mirror. A JDBC
   driver is client software, not a second PostgreSQL server.
4. Save the connection as `LOCAL • app • developer`. Open it and select the
   `app` schema. Avoid loading every database when you need only `app_local`.

| Field | Local exercise value |
|---|---|
| Host | `127.0.0.1` |
| Port | `5432` |
| Database | `app_local` |
| Authentication | Database-native username/password |
| Username | `app_local_dev` |
| Password | Generated password from the shared role-creation exercise |
| SSL / SSH | Disabled for this loopback-only disposable container |

[Connection wizard](https://dbeaver.com/docs/dbeaver/Create-Connection/).

Create a second connection named `LOCAL • app • reader` using
`app_local_reader` and its separate password. Check the username after copying
any connection; a new name does not change the underlying identity.

Open **SQL Editor → New SQL Editor** against the developer connection and run:

```sql
SELECT current_database() AS database_name,
       session_user AS login_role,
       current_user AS effective_role;

SELECT id, note FROM app.setup_check ORDER BY id LIMIT 10;
```

Run each statement deliberately with **SQL Editor → Execute SQL Statement**.
Expect database `app_local`, the selected login and the synthetic row. Repeat
with the reader connection; the data should match and the login should differ.
Use the shared [privilege checks](operations.md#2-use-and-verify-connections-safely)
to verify the reader cannot modify application tables or create schema objects.
Do not test denied writes against a real production table.
[SQL editor](https://dbeaver.com/docs/dbeaver/SQL-Editor/),
[statement and script execution](https://dbeaver.com/docs/dbeaver/SQL-Execution/).

## 5. Organize local, dev, test and production

Use these **custom project conventions**, not assumptions about DBeaver's
default colours. Group connections by environment and include the access level
in their names. Do not save a production login you have no reason to use.

| Environment | Example name / colour | Normal identity | Transaction choice |
|---|---|---|---|
| Local | `LOCAL • app • developer` / blue | Local developer | Explicitly inspect the mode before each exercise |
| Shared development | `DEV • app • developer` / green | Named, scoped developer | Manual for reviewed ad hoc changes |
| Test | `TEST • app • reader` / amber | Reader; separate approved test writer | Manual for any approved write |
| Production | `PROD • app • READ ONLY` / red | Named, database-enforced reader | Manual; finish sessions promptly |
| Production maintenance | `PROD • app • MAINTENANCE` / red | Separate time-bounded identity | Approved change procedure only |

In **Edit Connection → General**, choose the connection type. DBeaver's
Development and Test types default to auto-commit; Production defaults to
manual commit with execution/change confirmations. Use **Edit** beside the
type to review or customize it. Changes to a shared type affect other connections
using that type, so inspect the active session's settings after reconnecting.
[Connection types](https://dbeaver.com/docs/dbeaver/Connection-Types/).

For reader connections, enable **Read-only connection** in connection security
settings as an additional guard. The toolbar also offers a read-only toggle.
These client restrictions and confirmation dialogs supplement the server role;
they do not turn a privileged account into an enforced reader.
[Connection restrictions](https://dbeaver.com/docs/dbeaver/Managing-security-restrictions-for-database-connection/).

Production should have independent infrastructure, secrets and authorization.
Separate folders, workspaces and database names help organization but do not
provide a security boundary. Your database owner must review effective role
membership, ownership, callable functions and row-level access, not just the
presence of a SELECT grant.

## 6. Connect to shared dev, test and production

### Obtain infrastructure and access

The shared [remote-environment preparation](postgresql.md#4-prepare-shared-development-test-and-production)
lists the database owner's responsibilities. Complete it separately for dev,
test and production before configuring clients. The owner creates databases,
scoped roles, network policy, TLS and recovery arrangements. A DBeaver connection
does not provision any of these.

Start with development, then test. Add production only when access is approved.
Use synthetic or approved sanitized test data. Keep PostgreSQL major version,
extensions and migrations aligned with the application; this local tutorial
does not justify upgrading or changing a remote server.

### Connect using verified TLS

1. Create a PostgreSQL connection using the private worksheet's actual database
   hostname, port, database and individual identity. Prefer the normal connection
   fields to a credential-bearing URL.
2. Establish the required VPN/private network route first. Use the endpoint's
   certificate DNS name, not an arbitrary IP address.
3. Add the **SSL** tab using **+** in the connection editor if needed. Select
   **verify-full** and supply the approved CA certificate. Supply client
   certificate/key files only if the service requires mutual TLS.
4. If the driver presents these settings through **Driver properties**, use
   `sslmode=verify-full` and the approved `sslrootcert` file instead. Check for
   conflicting GUI/driver overrides; use one consistent configuration.
5. Test the connection, confirm its environment/name and complete the verification
   below. Preserve certificate verification when troubleshooting.

Field availability depends on the selected driver.
[DBeaver SSL configuration](https://dbeaver.com/docs/dbeaver/SSL-Configuration/).

For PostgreSQL JDBC, `verify-full` validates the certificate chain and hostname;
`require` alone does not provide the same identity checks. Do not use a
non-validating socket factory or disable hostname validation to get a green
connection test. Obtain the correct CA, endpoint or network route from the owner.
[PostgreSQL JDBC TLS modes](https://jdbc.postgresql.org/documentation/ssl/).

### Add an SSH tunnel only when required

1. Keep the database's **Main** host set to the address reachable from the
   approved SSH host. Use `localhost` there only if PostgreSQL actually runs on
   that SSH host; a separate bastion normally needs the real database address.
2. Add the **SSH** tab with **+**. Enter the bastion host, SSH port and your
   named SSH account. Select the approved public-key or agent authentication.
   Use the existing approved SSH agent where supported rather than exporting
   a private key just for this client.
3. Verify the bastion fingerprint through the approved channel. Leave
   **Bypass host verification** disabled.
4. Test the tunnel, then test the database connection. SSH authentication and
   database authentication are separate checks.

Keep database TLS enabled when required. Confirm that the tunnel configuration
still verifies the database certificate's hostname. If it does not, have the
owner provide a supported configuration; do not bypass validation.
[SSH tunnel configuration](https://dbeaver.com/docs/dbeaver/SSH-Configuration/).

### Verify each environment before use

Run the shared [session, TLS and permission checks](operations.md#2-use-and-verify-connections-safely)
in a fresh SQL editor for each connection. Confirm the database, login,
effective role and expected server. Check the editor's selected data source
before execution. A successful connection test proves connectivity, not that
the endpoint or permissions are appropriate for the task.

The server-side TLS check does not prove that the client validated the hostname;
review both the client setting and server result. Poolers and replicas may
change the interpretation of server address or TLS observations. Ask the owner
which endpoint is intended and how to verify it. Use a supported direct endpoint
for operations that the pooler cannot support.

## 7. Connect VS Code to the same databases

Follow [Connect VS Code to PostgreSQL](vscode.md). It covers the Microsoft
extension, independent credentials, TLS, SSH and connection verification.
Then use the optional SQL-file handoff below if you want to open the same
reviewed query in DBeaver.

## 8. Open a SQL file from VS Code in DBeaver

This optional workflow hands a saved local SQL file to DBeaver. It does not
synchronize connections, choose a production database or execute the SQL.
Use it in a local macOS VS Code window with DBeaver installed in Applications.

1. Open DBeaver normally with the intended workspace first.
2. In VS Code, run **Tasks: Open User Tasks**. If the file already has tasks,
   merge the new object into its `tasks` array; do not overwrite existing tasks.
3. Add this user task:

   ```json
   {
     "version": "2.0.0",
     "tasks": [
       {
         "label": "Open current SQL file in DBeaver",
         "type": "process",
         "command": "/Applications/DBeaver.app/Contents/MacOS/dbeaver",
         "args": ["-f", "${file}"],
         "problemMatcher": []
       }
     ]
   }
   ```

4. Save a harmless `.sql` file, make its editor active and run **Tasks: Run Task →
   Open current SQL file in DBeaver**. Unsaved editor changes are not a file handoff.
5. In DBeaver, select and verify the intended data source/schema before running
   a statement. Review any existing association; the file name is not proof of
   its environment.

Make edits in one editor at a time and reload external changes before saving in
the other, so one client does not overwrite the other's SQL-file edits.

The process task passes the filename as one argument, including spaces.
`${file}` refers to the active file.
[VS Code user tasks](https://code.visualstudio.com/docs/debugtest/tasks),
[variable reference](https://code.visualstudio.com/docs/reference/variables-reference).

DBeaver documents `-f` for opening a file and the macOS executable path used
above. If your approved installation is elsewhere, adjust only the executable
path. Do not add credentials, automatic connection flags or forced workspace
reuse. If DBeaver reports a locked workspace, return to the existing instance;
do not force a second process to write the same workspace.
[DBeaver command line](https://dbeaver.com/docs/dbeaver/Command-Line/).

This task is not a Remote SSH/Dev Container recipe: the macOS executable and
local file path may not exist where a remote task runs. Use the PostgreSQL
extension in the intended environment or the approved local file workflow.

## 9. Run queries and promote changes

### Daily query workflow

1. Check the active connection, database, login and schema before running SQL.
   Start with a bounded read, using qualified names such as `app.setup_check`.
2. Distinguish **Execute SQL Statement** from **Execute SQL Script**. Review the
   selected text and script contents before choosing either.
3. For approved changes, inspect the actual transaction mode first. With
   auto-commit, each successful statement is committed immediately. In manual
   mode, review the pending work and explicitly **Commit** or **Rollback**.
4. Finish transactions and disconnect when done. Even a reader left idle in a
   transaction can retain a snapshot and interfere with maintenance.
5. Save reusable, credential-free SQL in the application repository. Keep
   query results and private connection configuration out of it.

Do not rely on a rollback button after an auto-committed change. Transaction
controls also do not replace review of statements that cannot run inside a
transaction or calls with external effects.
[DBeaver commit modes](https://dbeaver.com/docs/dbeaver/Auto-and-Manual-Commit-Modes/).

Use result limits and filters before opening large tables. Avoid importing or
exporting a whole production dataset for a quick check. If a query is expensive,
cancel it and involve the database owner before raising timeouts or resource
limits. Treat query plans and result exports as potentially sensitive.

### Application identities and schema migrations

Follow the shared [application configuration and migration procedure](operations.md#1-configure-applications-and-promote-migrations).
Use `app_local_runtime` for the example application's connection, not the
developer login. A GUI client configuration does not configure the application.

Keep migrations in the application's existing framework and delivery pipeline.
Review them locally, then promote the same artifact through dev and test before
an approved production change. DBeaver is useful for inspection and reviewed
queries; an ad hoc table edit is not a reproducible migration. In the local
exercise, objects intended to receive the configured default grants must be
created as `app_local_owner`, as the shared setup explains.

Production maintenance uses a separate temporary identity, a reviewed change,
bounded scope and a recovery plan. Keep normal production browsing read-only.
This guide does not enable AI/MCP database access; DataGrip-specific integration
instructions should not be copied into DBeaver configuration.

## 10. Back up and rehearse recovery

### Container-based local exercise

Use the existing [local backup and isolated restore rehearsal](operations.md#3-back-up-and-rehearse-a-restore).
It uses `pg_dump`/`pg_restore` inside the existing container, a private unique
archive path and a new `app_local_restore_check` database. It requires no second
PostgreSQL installation on the Mac.

Run its steps individually, stopping on failure. Keep the source database
unchanged. Verify restored data, ownership and access with the intended roles;
database-level grants and cluster roles need deliberate handling. A backup
file's existence is not evidence that recovery works.

### Optional DBeaver backup/restore UI

DBeaver Community supports PostgreSQL native backup and restore. Its GUI needs
compatible **local PostgreSQL client binaries**, separately from the JDBC
driver. The tools inside a container are not automatically a macOS client-tool
installation for the wizard.

If your team supplies native tools, use the database's **Tools → Backup** action,
select the approved local client and a private output path, review the format
and options, then check the completion log. Use **Tools → Restore** only against
a new, isolated target with the required roles and permissions prepared. Avoid
options that clean/drop existing objects or discard ownership/ACLs unless the
specific recovery procedure requires and reviews them.
[DBeaver native backup and restore](https://dbeaver.com/docs/dbeaver/Backup-Restore/).

For the first local rehearsal, prefer the complete container procedure above.
Do not install or start another database server just to supply GUI backup tools.
A CSV export or DBeaver workspace export is not a PostgreSQL recovery backup.

### Shared and production recovery

The service owner manages automated backups, retention, point-in-time recovery
where required, and restore exercises against agreed RPO/RTO targets. A desktop
export is not a substitute. Rehearse restoration on approved isolated
infrastructure; do not copy live production data onto this Mac for this guide.

## 11. Maintain the installation and private configuration

Update DBeaver through its chosen owner: company management, the selected
manual distribution or Homebrew. Do not introduce a second updater without
reviewing ownership. After client or driver changes, check local/dev first,
then verify required TLS, authentication and permissions before production use.

Rotate credentials and certificates through their owners. Refresh each client's
configuration separately, reconnect, verify the new identity and retire obsolete
access. Remove unneeded saved connections after checking for pending work.

Back up private workspace configuration through the approved encrypted process
with DBeaver closed. Review exports for secrets, hostnames, query history and
results before sharing. Rebuild connections from the private worksheet when
moving Macs; do not copy an entire old workspace into a public dotfiles repo.

Review container disk use and stop disposable services when unnecessary. Keep
the database volume until you have reviewed its contents and backup needs.
Never point a new PostgreSQL major version at an old data volume as an upgrade
shortcut; use the application's tested database upgrade procedure.

## 12. Troubleshoot the connection

| Symptom | Checks and next action |
|---|---|
| DBeaver is installed but `dbeaver` is not in Terminal PATH | Open the app normally; the optional VS Code task uses its bundle executable. A missing launcher alone does not prove the app is absent |
| JDBC driver download fails | Check the approved proxy/mirror and network policy; do not disable TLS verification or fetch a random driver archive |
| Local connection refused | Confirm engine/context, container health and published port; use the existing owner's lifecycle commands |
| Port 5432 is occupied | Identify the owning process. Reuse the intended service or agree another project-owned loopback port; do not kill an unrelated service |
| Password authentication fails | Check environment, username, database and password expiry; do not reset the bootstrap account or reuse production credentials locally |
| Cloud SSO option is unavailable | Check Community edition support and organization policy; use an approved compatible client/edition |
| TLS certificate or hostname fails | Check endpoint DNS, CA chain, expiry, Mac clock and tunnel settings; obtain corrected configuration without bypassing verification |
| SSH succeeds but the database fails | Check the database address from the bastion, database port, database identity and TLS separately |
| Connection succeeds but the schema is missing | Select `app`, refresh metadata and verify CONNECT/USAGE and table privileges; request the precise missing grant |
| A change appears in one client only | Check endpoint/database, transaction commit and the other client's snapshot/cache; finish or refresh deliberately |
| Production allows unexpected writes | Stop using that connection for normal browsing and ask the owner to correct effective grants/role membership; the GUI read-only toggle alone is insufficient |
| VS Code connects locally but fails in a remote window | Check extension location and its own network/loopback context; configure the approved route there |
| SQL handoff does not open the expected contents | Save the file, make it active, use a local window and check the installed app path; do not force concurrent workspace access |
| GUI backup reports missing native tools | Use the container backup recipe or the approved compatible client binaries; downloading a JDBC driver does not supply `pg_dump` |
| Queries or browsing are slow | Limit rows/schemas, finish idle transactions and check service health; investigate before raising container limits or running heavy diagnostics |

For escalation, provide the client/driver version, environment label, time and a
redacted error message. Remove passwords, connection URLs, tokens, private
endpoints and result data from anything posted publicly.

## 13. Completion checklists and references

### Local setup complete

- [ ] One approved DBeaver installation owner; correct Apple-silicon build.
- [ ] Existing local service reused or one server route completed deliberately.
- [ ] Database/roles created once, or the application's own migrations used.
- [ ] Developer and reader connections show the intended database and identities.
- [ ] DBeaver and VS Code return the same synthetic row through independent connections.
- [ ] Reader permissions verified; passwords and private configuration stay outside Git.
- [ ] Optional SQL handoff opens a saved file without executing it.
- [ ] Backup restores successfully into a separate local target, if using the example.

### Each shared environment ready

- [ ] Owner, endpoint type, identity, permitted work and recovery procedure recorded privately.
- [ ] Authentication supported by the selected client and approved by the organization.
- [ ] Network route and verified TLS work in each client independently.
- [ ] Database-enforced production reader verified; maintenance access remains separate.
- [ ] Connection labels, confirmation settings and actual commit mode checked.
- [ ] Migration promotion and service recovery tested by their owners.

### Sources and related guides

Official documentation is linked next to the relevant steps. Menu labels and
edition availability can change; recheck those sources after upgrades. This
guide supplies configuration procedures, not evidence that a particular hosted
database or organization's access controls have passed acceptance testing.

- [DBeaver Community downloads](https://dbeaver.io/download/) and
  [DBeaver documentation](https://dbeaver.com/docs/dbeaver/).
- [PostgreSQL 17 documentation](https://www.postgresql.org/docs/17/) and
  [JDBC TLS configuration](https://jdbc.postgresql.org/documentation/ssl/).
- [Microsoft PostgreSQL extension](https://learn.microsoft.com/en-us/azure/postgresql/developer/vs-code-extension/vs-code-overview).
- [Manual container setup](containers.md),
  [shared PostgreSQL procedures](postgresql.md), [DataGrip guide](datagrip.md),
  [manual VS Code profiles](../editors/vscode.md) and
  [software catalogue](../../../shared/reference/software-catalogue.md).
