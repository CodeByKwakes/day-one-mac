# Database setup and operations

Choose the shared foundation first, then a client. All clients can use the same
local, development, test and production servers with their own connections.
Hosting remains provider-neutral; the service owner supplies approved endpoints,
identities, network access and recovery requirements.

1. [PostgreSQL foundation](postgresql.md): local service, environment boundaries,
   roles and shared infrastructure prerequisites.
2. Choose [DataGrip](datagrip.md) or [DBeaver Community](dbeaver.md) for a desktop
   client, or use both without provisioning duplicate databases.
3. [Connect VS Code](vscode.md) using the same server and appropriate identity.
4. [Database operations](operations.md): application connections, migrations,
   verification, backups and restore rehearsals.

[Manual local containers](containers.md) covers the container lifecycle.
Remote provisioning and permissions remain explicit administrator work. [All application guides](../apps/README.md).

For a new synthetic sandbox, use the complete [manual container task](containers.md).
