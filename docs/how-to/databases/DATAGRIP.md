[← Application guides](../apps/README.md) · [Local database module](../modules/optional/09-databases.md) · [VS Code profiles](../apps/VSCODE-PROFILES.md)

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
Both clients reuse the [PostgreSQL foundation](POSTGRESQL.md) and
[operations procedures](OPERATIONS.md). Do not create a
second database or rerun role creation just to add another client.

DataGrip is optional and is not installed or configured by Day One Mac's
application catalogue. Database access is a shared manual action on both setup
routes. Module 09 provisions only the selected local containers; it does not
provision remote environments or apply your application's migrations.

## Contents

1. [Plan environments and access](POSTGRESQL.md#1-plan-environments-and-access)
2. [Install DataGrip and prepare the clients](#2-install-datagrip-and-prepare-the-clients)
3. [Start a local PostgreSQL server](POSTGRESQL.md#3-start-a-local-postgresql-server)
4. [Create a local example database and roles](POSTGRESQL.md#4-create-a-local-example-database-and-roles)
5. [Connect DataGrip to local PostgreSQL](#5-connect-datagrip-to-local-postgresql)
6. [Prepare shared development, test and production](POSTGRESQL.md#6-prepare-shared-development-test-and-production)
7. [Connect DataGrip to remote environments](#7-connect-datagrip-to-remote-environments)
8. [Connect VS Code to the same databases](VSCODE.md#8-connect-vs-code-to-the-same-databases)
9. [Configure applications and promote migrations](OPERATIONS.md#9-configure-applications-and-promote-migrations)
10. [Use and verify connections safely](OPERATIONS.md#10-use-and-verify-connections-safely)
11. [Back up and rehearse a restore](OPERATIONS.md#11-back-up-and-rehearse-a-restore)
12. [Optional SQL handoff and AI access](#12-optional-sql-handoff-and-ai-access)
13. [Troubleshoot and maintain the setup](#13-troubleshoot-and-maintain-the-setup)
14. [Completion checklists and source references](#14-completion-checklists-and-source-references)

## 1. Plan environments and access

Follow the maintained [procedure](POSTGRESQL.md#1-plan-environments-and-access).

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

Complete [VS Code base setup](../apps/VSCODE.md). If using the project profiles, select
Full Stack for development and Operations for production investigation in the
[profile guide](../apps/VSCODE-PROFILES.md). These profiles organize tools; they do not
isolate saved credentials. Install the PostgreSQL extension in section 8.

No separate PostgreSQL server, Java installation or Homebrew database service
is required merely to connect DataGrip to an existing server. The local
tutorial uses the PostgreSQL tools already inside its container.

## 3. Start a local PostgreSQL server

Follow the maintained [procedure](POSTGRESQL.md#3-start-a-local-postgresql-server).

## 4. Create a local example database and roles

Follow the maintained [procedure](POSTGRESQL.md#4-create-a-local-example-database-and-roles).

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

Follow the maintained [procedure](POSTGRESQL.md#6-prepare-shared-development-test-and-production).

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

Follow the maintained [procedure](VSCODE.md#8-connect-vs-code-to-the-same-databases).

## 9. Configure applications and promote migrations

Follow the maintained [procedure](OPERATIONS.md#9-configure-applications-and-promote-migrations).

## 10. Use and verify connections safely

Follow the maintained [procedure](OPERATIONS.md#10-use-and-verify-connections-safely).

## 11. Back up and rehearse a restore

Follow the maintained [procedure](OPERATIONS.md#11-back-up-and-rehearse-a-restore).

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

For local container behaviour, [Module 09](../modules/optional/09-databases.md) and
its current implementation remain authoritative. For editor extension/profile
assignments, use [VS Code profiles](../apps/VSCODE-PROFILES.md). Recheck vendor UI labels
against the installed versions when they differ from this guide.

---

[Application guides](../apps/README.md) · [Local databases](../modules/optional/09-databases.md) · [VS Code profiles](../apps/VSCODE-PROFILES.md) · [Security handbook](../../setup/manual/security.md)
