[← Reference library](README.md) · **Optional and advanced status** · [Optional modules](../02-optional/README.md)

# Optional and advanced status dashboard

Use one read-only command to review Modules 09–22:

```bash
day-one-mac optional --status
```

The dashboard reads the saved optional plan, installed payloads, Docker state,
Day One Mac ownership records, and Advanced completion fingerprints. It never
installs software, starts a container, edits configuration, or marks a manual
checklist complete.

## Status meanings

| Status | Meaning | What to do |
|---|---|---|
| `ready` | The result has sufficient machine-verifiable evidence, or an Advanced guide fingerprint is current. | No action is required. |
| `partial` | Some evidence exists, but a sign-in, application UI, security, or trust checklist still needs human verification. | Open the module guide and complete its checklist. |
| `pending` | The module is selected, but the dashboard found no completion evidence. | Start or resume the module guide. |
| `review` | A recorded guide changed, or detected ownership needs review. | Recheck the named evidence before recording completion again. |
| `blocked` | A selected prerequisite or runtime is unavailable. | Resolve the printed blocker, then rerun the dashboard. |
| `not selected` | The saved optional plan does not include the module and no Advanced completion marker exists. | Nothing is required. |

`partial` is expected for modules that contain actions the scripts cannot
safely inspect, such as authentication, provider trust, Warp imports, or an
application's private settings database. It does not mean the detected work
failed.

## Run the full audit

Generate the module dashboard plus the existing environment and repository
audits:

```bash
day-one-mac optional --status --audit
```

The command writes private, permission-restricted reports under
`~/.day-one-mac/`:

```text
optional-and-advanced-audit.md  Modules 09–22, evidence, and next actions
advanced-audit.md               Required base, tools, authentication, and drift
repository-audit.tsv            Repository state summary
```

Choose another destination when the reports must be reviewed or archived
elsewhere:

```bash
day-one-mac optional --status --audit \
  --report "/absolute/private/path/module-audit.md"
```

The companion environment and repository reports are written beside the
requested module report. The audit does not print credential files, tokens, or
MCP secret values.

## Use it as a verification gate

For a script or maintenance check, return a non-zero status when any selected
module is blocked, pending, partial, or needs review:

```bash
day-one-mac optional --status --check
```

This strict mode treats `partial` as unfinished because its manual checklist
has not been verified automatically. Modules marked `not selected` do not
cause failure.

Combine both flags to enforce the selected-module gate and the required-base
environment gates from the full audit:

```bash
day-one-mac optional --status --audit --check
```

## Resolve common results

### Database is blocked

The database installer starts an installed OrbStack instance and waits for its
bundled Docker CLI and server. If OrbStack displays a first-run prompt,
complete it and wait until Docker is running. Do not install a separate Docker
engine merely because the first readiness check timed out.

Confirm `docker info` displays a Server section, then run:

```bash
day-one-mac databases --saved
day-one-mac databases --saved --check
```

### AI, OmniRoute, MCP, profiles, or Warp is partial

The dashboard found an installed payload or configuration but cannot prove the
private sign-in, provider, trust, profile-purpose, or application-import steps.
Open the module's installed guide and complete its final checklist:

```bash
day-one-mac docs optional --open
```

### Advanced module needs review

Its recorded fingerprint no longer matches the current guide:

```bash
day-one-mac advanced --module 18
day-one-mac advanced --complete 18
```

Replace `18` with the reported module number. Record completion only after the
current checklist passes.

---

[← Command reference](COMMAND-REFERENCE.md) · [Optional modules](../02-optional/README.md) · [Advanced modules](../03-advanced/README.md)
