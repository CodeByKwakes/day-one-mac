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
