# Connect VS Code to PostgreSQL

**Document type:** how-to. **Source verification:** 15 October 2026.

Use the server and personal identity prepared in the [PostgreSQL foundation](POSTGRESQL.md). VS Code, [DataGrip](DATAGRIP.md) and [DBeaver](DBEAVER.md) establish independent connections; they do not synchronize passwords or tunnels. [Database guide index](README.md).

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
   same friendly name used in your desktop client. Enter the password separately.
3. Open **Advanced**: set **Scope → User**, port and a recognizable application
   name. User scope keeps this definition out of the repository's workspace
   settings; review Settings Sync and profile exports separately.
4. Configure SSL and, if needed, SSH as described below.
5. Use **Test Connection**, then **Save & Connect**. Save Password is optional;
   Microsoft stores it through VS Code SecretStorage, backed by macOS Keychain.
6. Group connections by environment. Create/open a query from the intended
   connection and verify its database/user with the [session verification procedure](OPERATIONS.md#10-use-and-verify-connections-safely) before querying.

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
port opened internally by another database client. Verify TLS still succeeds through this route.
[Microsoft advanced connection options](https://learn.microsoft.com/en-us/azure/postgresql/development/vs-code-extension/advanced-connection-options).

For the local exercise, run `SELECT id, note FROM app.setup_check LIMIT 10;` in
both editors. Matching results plus the identity query confirm that both clients
reach the intended database. With a remote replica or pooler, confirm the
endpoint with its owner; identical labels alone are not proof.

If using Remote SSH or a Dev Container, check where the extension actually runs.
`127.0.0.1` refers to that execution environment. Establish its approved network
route and credential storage separately; never expose the local database on all
interfaces just to make a remote editor reach it.
