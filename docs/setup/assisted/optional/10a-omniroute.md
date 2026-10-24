# Optional 10A: create an owned OmniRoute container

Use the assisted operation to manage a reviewed, digest-pinned local gateway
container. Complete Phase 8, select an AI client and verify the intended local
Docker context before applying. A gateway does not grant a client permission
to edit files or run commands.

## Executable digest-pinned container route

Module 10A can create and resume one owned local gateway. It does not install
or start the container engine, set up providers, supply keys, change billing or route any
client. Start your chosen engine yourself and complete Phase 8 before applying.

Choose a reviewed release from the [upstream Docker guide](https://github.com/diegosouzapw/OmniRoute/blob/release/v3.8.51/docs/guides/DOCKER_GUIDE.md)
and obtain its image digest from the publisher's registry metadata. A digest
identifies exact image content; a tag such as `latest` can move. Review the
publisher and release as well: a digest alone is not a safety certificate.

In an editor, create `omniroute.tsv` using real tabs:

```text
context	orbstack
image	diegosouzapw/omniroute@sha256:REPLACE_WITH_REVIEWED_64_CHARACTER_HEX_DIGEST
port	20128
```

The placeholder is deliberately rejected. Replace it with the reviewed
64-character lowercase hexadecimal digest; no default digest is supplied.

```bash
day-one-mac optional --module 10A --plan --manifest ./omniroute.tsv
day-one-mac optional --module 10A --apply --manifest ./omniroute.tsv
day-one-mac optional --module 10A --check
```

Plan prints the proposal without contacting Docker. Apply verifies that
`orbstack` uses a local Unix socket and checks for conflicts. It never changes
your global Docker context. The fixed container is `omniroute`, its named
volume is `omniroute-data` mounted at `/app/data`, and the port binds only to
`127.0.0.1`. Budget for a 10 GiB container memory limit and an 8192 MiB runtime
setting. API-key enforcement is enabled, but keys are not created for you.

Docker [creates the container before starting it](https://docs.docker.com/reference/cli/docker/container/create/);
the runner checks the image, ownership labels, ports, mount, network, security
options, memory, command and environment before starting it. Success requires
the image's built-in healthcheck to pass within the bounded wait. This proves
container health, not provider authentication or a successful model request.

After an interruption, inspect the printed run journal and use:

```bash
day-one-mac optional --module 10A --resume
day-one-mac optional --module 10A --check
```

Resume preserves data and skips creation for a matching owned container.
Conflicting or unowned resources are never adopted, replaced or deleted.
Resources created using the older manual commands below lack the new
ownership labels and need a separately reviewed migration; do not relabel
them just to bypass the check. An image/port change also requires a separately
reviewed migration, not automatic replacement.

If using this route, skip the manual container creation commands below and
continue with provider, endpoint-key and client setup once health passes.
Do not run both container creation routes. No rollback or volume cleanup is
performed automatically.

## Complete dashboard and client configuration

Follow the [manual dashboard, endpoint-key and client steps](../../manual/ai/omniroute.md)
using the container just created. Skip its manual container-creation step.
Expected result: the gateway and selected client complete a harmless request
with the intended provider and billing account. Return to the module check
only after that separate client test succeeds.

## Troubleshooting and recovery

A healthy container does not prove a provider credential or model identifier
works. Inspect dashboard access, endpoint authentication and provider errors
separately. Preserve the gateway volume until recovery is verified. Use the
[module execution reference](../reference/module-execution.md) for saved-operation
checks and removal; do not use global Docker prune.
