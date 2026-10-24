[← Required Phase 8](../08-verify-and-reproduce.md) · **🤖 ⚙️ Optional 9** · [AI clients →](10-ai-agents.md)

# Optional 9 - Local databases with containers

**Time:** 15-45 minutes · **Required:** only when a current project needs it

In this guide, a Docker **volume** means persistent database data stored
separately from its container. It is not the encrypted external backup volume
used by Stage 0.

## Current safety contract

The script-assisted module is for **synthetic disposable data only**. Review a
plan, then pass `--disposable-data` to acknowledge its fixed development
credentials. Saved acknowledgement is reused on resume. Use separately managed
services for sensitive data. The guided picker states the same restriction.

```bash
day-one-mac optional --module 09 --plan --services postgres
day-one-mac optional --module 09 --apply --services postgres --disposable-data
```

Apply requires current Phase 8 evidence. Docker endpoint overrides are refused;
all operations use an inspected, recorded local Unix-socket context. Context
changes require a deliberate migration review. Existing unlabelled resources
are refused, preserved and never silently adopted. Export and test restoration
before planning any migration; see [recovery acceptance](../../../shared/verification.md).

Images resolve to recorded registry digests on first apply. Each service has
2 GiB/two CPU limits, no automatic restart and launch-specification drift checks.
Commands below that use `unless-stopped` describe manual examples; they are not
accepted automatically as script-owned resources. Keep manual and assisted
ownership separate. Credentials in this guide are development examples only.

## Outcome

A selected database runs in an isolated container with a named volume, a health
check, documented development credentials, and an explicit backup/removal
procedure. Skipping this module does not affect the required setup.

## Run the assisted operation

Both paths create the same container names, volumes, ports, and health checks.
Do not mix paths during the initial setup.

### Preview and apply the selected services

If Databases was saved in the Optional Setup Center, install or resume exactly
those services:

```bash
day-one-mac databases --saved
```

Or name the services directly:

```bash
day-one-mac databases --services postgres,redis --dry-run
day-one-mac databases --services postgres,redis --disposable-data
```

The installer preserves existing containers and volumes, starts a stopped
selected container only when its image, localhost binding, named volume and
network match the expected configuration, waits for its health check, and writes
`~/.day-one-mac/database-status.md`. Check it later with:

```bash
day-one-mac databases --saved --status
```

Choose **Docker Desktop** or **OrbStack** in the optional wizard, or explicitly:

```bash
day-one-mac databases --services postgres,redis --container-runtime docker --disposable-data
# Alternative:
day-one-mac databases --services postgres,redis --container-runtime orbstack --disposable-data
```

`auto` reuses a working Docker context, then detects an installed engine. When
neither exists it asks you to choose; unattended runs must supply the choice.
The selected engine is saved for resume. The installer checks application
ownership, starts the selected application, locates its bundled CLI and waits
up to 60 seconds for `docker info`. Both engines supply the Docker CLI; a
separate `brew install docker` supplies no engine and is unnecessary here.

That startup/install behaviour is apply-only. Preview works before Phase 8,
does not start either engine, and labels proposed creates as conditional when the
engine cannot be inspected. Apply still requires Phase 8. A running container
without a passing health check is not considered verified.

The equivalent shared interface is
`day-one-mac optional --module 09 --plan --services postgres,redis`, followed
by `--apply`, `--check`, or `--resume`. See the
[module execution reference](../reference/module-execution.md) for
saved selections, private run journals and recovery.

Either application can display first-run permission or licence prompts that automation
must not approve for you. Complete any visible prompt. If the readiness wait
expires, confirm that the selected application reports Docker as running, verify that
`docker info` shows a **Server** section, and rerun the same command. Do not run
Docker with `sudo`.

After installation, complete the connection and backup checks below.

## Complete the shared manual checks

1. Confirm the selected container health and loopback port in the printed status.

   Expected result: the selected services report healthy on the local context.

2. Follow [PostgreSQL connection and role setup](../../manual/databases/postgresql.md)
   only for the capability you selected. Use the existing module-owned service;
   skip manual container creation.

   Expected result: an authorised client connects to the intended local database.

3. Follow the [database backup and restore procedure](../../manual/databases/operations.md)
   before retaining data or planning destructive work.

   Expected result: a tested recovery copy exists for data you intend to retain.

Return to `day-one-mac optional --module 09 --check` after the client check.
It checks module state and services; it does not certify every application query.

## Troubleshooting and recovery

Use `day-one-mac databases --saved --status` to inspect the selected service state.
If the engine is unavailable, open its approved app and complete first-run
prompts, then resume the saved selection. Do not run Docker with `sudo`.
For ownership conflicts, preserve the existing resource and review its labels,
ports and volume before choosing a separate setup.

The module's recorded operation and [recovery reference](../reference/module-execution.md)
own removal. A container stop is different from deleting its persistent volume.
Never use an unrestricted prune as a repair step.
