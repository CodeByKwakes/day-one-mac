# Keep setup evidence private

Use a user-selected private folder outside repositories and installed skills.
The manual maintenance recipes use the following default for non-secret reports.
Before running the commands, inspect any existing directory and its ownership.
Stop on an unexpected symlink, shared location or owner; choose another approved
private location and adapt the calling recipe's paths when needed.

```bash
umask 077
mkdir -p "$HOME/.local/state/development-setup"
chmod 700 "$HOME/.local/state/development-setup"
```

Expected: the directory exists and only your account can access it. Stop on any
permission failure before saving a report.

Keep reports limited to the selected task. Never include credentials, recovery
codes or unrelated account inventories. Include relevant versions, scope,
expected/actual results and recovery references. A report is evidence, not a data
backup or proof that a later session is still configured correctly.

Use `umask 077` before creating report files and verify their permissions. Store
recovery copies through the selected encrypted backup owner. Follow
[verification](verification.md) and [troubleshooting](troubleshooting.md) for
what to check and which non-secret details help resolve a failure.

## Copy a setup acceptance record

Copy this blank template into your private folder, then replace the bracketed
fields. Use **pass**, **fail**, **skipped** or **untested** for each result. A skipped
optional capability needs a reason; an untested required control remains incomplete.
The [verification guide](verification.md) owns the required controls and expiry rules.

```text
Setup route: [manual or AI-assisted; client and assistance mode if selected]
Device reference: [private non-secret label]
Ownership and policy: [personal or managed; responsible owner]
macOS version/build and architecture: [observed values]
Guide/skill/plugin source: [revision, artifact version and checksum where available]
Review date and reviewer: [date and name]
Evidence expiry: [date required by the selected policy]

Capability: [one selected task]
Installation owner and version: [observed values]
Expected result: [the guide's check]
Command or UI action: [non-secret description]
Observed result: [what happened]
Status: [pass / fail / skipped / untested]
Recovery copy and restore check: [private reference and observed outcome]
Remaining action and owner: [action, responsible person or intentionally none]

Final project check: [repository reference, command and result]
Restart/new-session check: [observed result]
Independent sample restore: [observed result]
Outstanding required checks: [list; do not mark setup complete while unresolved]
```

Repeat the capability block for each selected task. Record account access without
copying tokens, private keys, recovery codes or complete diagnostic inventories.
