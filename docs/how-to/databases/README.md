# Database setup and operations

Choose the shared foundation first, then a client. All clients can use the same
local, development, test and production servers with their own connections.
Hosting remains provider-neutral; the service owner supplies approved endpoints,
identities, network access and recovery requirements.

1. [PostgreSQL foundation](POSTGRESQL.md): local service, environment boundaries,
   roles and shared infrastructure prerequisites.
2. Choose [DataGrip](DATAGRIP.md) or [DBeaver Community](DBEAVER.md) for a desktop
   client, or use both without provisioning duplicate databases.
3. [Connect VS Code](VSCODE.md) using the same server and appropriate identity.
4. [Database operations](OPERATIONS.md): application connections, migrations,
   verification, backups and restore rehearsals.

[Optional local database module](../modules/optional/09-databases.md) owns the
script-assisted container lifecycle. Remote provisioning and permissions remain
explicit administrator work. [All application guides](../apps/README.md).
