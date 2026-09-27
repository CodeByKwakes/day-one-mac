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

Saved database and CLI selections made through the executable module interface
also count as selected, without requiring the interactive selector. CLI checks
include selected pre-existing formulae without treating them as Day One-owned.
Database readiness requires passing health and configuration checks, not merely
a running container. See [Module execution](MODULE-EXECUTION.md).

Saved Module 10 client choices and Module 16 software snapshots also count as
selected. Their payload-only `--check` can pass while the dashboard remains
`partial`: AI authentication, Brewfile declarations, licences and settings
are not machine-verified. Missing/conflicting Module 16 payloads require
`review`. A guide fingerprint alone is not substituted for a saved selection's
live payload check. The strict dashboard gate therefore remains nonzero for
these manually unfinished workflows. After a user explicitly records the
current Module 16 checklist with `advanced --complete 16`, it can be `ready`
only if the live payload check also passes. A stale guide or failed payload
check remains `review`; manual completion is user-attested, not inferred.

## Status meanings

Saved Module 18 identity manifests and Module 20 restore selections count as
selected. Passing checks remain `partial`: configuration changes, provider
authentication, actual signing, worktree lifecycle and live migration are not
performed. A no-restore decision is verified without a mounted disk but still
does not attest the guide checklist. Drift, missing backup volumes, staging
conflicts and invalid records produce `review`; a guide marker cannot override
these executable checks. Module 21 includes both modules in its saved-selection
audit and drift report.

Saved Module 15/17 artifact selections and Module 19 preference choices also
count without the wizard. Passing checks stay `partial`: chezmoi import, shell
activation and GUI/security review remain manual. Dotfile/helper drift,
conflicting project declarations, changed typed preferences or invalid records
produce `review`. A guide-completion marker cannot override a failed executable
check for those saved selections.

Saved Module 10A/11/22 selections also count without the wizard. Module 10A
checks the owned digest-pinned gateway in its explicit local Docker context.
Module 11 checks generated MCP artifacts, not live client configuration.
Module 22 compares selected skill/MCP metadata with its evidence snapshot.
Passing checks stay `partial` because provider readiness, activation and trust
remain manual; a failed check or drift is `review`. A guide marker does not
override these executable-scope checks.

Generated Module 12/14 artifacts count as selected even without the wizard.
Valid files are `partial` because application import, workspace choice and
Sync state remain manual. Invalid/missing outputs or changed Warp source are
`review`. Module 21 additionally checks live bounded evidence against its
latest snapshot; drift or failed evidence means `review`. With clean evidence
and a current user-confirmed Module 21 guide marker it can be `ready`; without
that marker it remains `partial`. None of these states proves full machine
health or successful application import.

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
