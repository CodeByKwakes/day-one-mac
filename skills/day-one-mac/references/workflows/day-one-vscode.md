# Day One VS Code

Use the [editor guide](../project/docs/setup/manual/editors/vscode.md) for profile
assignments, extension tradeoffs and manual verification. The
[profile configuration](../project/config/profiles/vscode/profiles.json) owns the
recipe values. Read only the sections needed for the requested change.

## Establish the target

Identify the VS Code distribution, installed version, named profiles and requested
operation: inspect, add, merge, replace, export, restore or remove. Check whether
the window is local, remote or a Dev Container. Local User Settings and local
extensions do not prove a remote workspace uses the same configuration.

Use the Profiles editor to establish exact names. A CLI command with an unknown
profile name can create an empty profile. For direct file changes, obtain the
settings path from that profile's User Settings editor; never guess profile IDs.
Treat internal profile metadata as read-only evidence, not a supported write API.

Inspect sharing with Default, Settings Sync, Workspace Settings and language
overrides before diagnosing a value that appears ineffective. Distinguish the
recipe's inheritance from VS Code's actual resource-sharing choices. Keep
personal preferences in profile User Settings unless the user requests team rules.

## Plan and apply the selected change

- For an audit, report effective settings, extension versions and conflicts
  without changing files or installing extensions.
- Verify extension identifiers, current compatibility and contributed settings
  against their published manifest and primary documentation. Flag unsupported
  settings, overlapping formatters and extensions that write workspace files.
- Preview the profile, keys, old/new values, extension additions/removals and
  recovery path. Reuse existing approval for that exact scope; ask only when
  ownership or the intended change is unresolved.
- Merge requested keys by default. Preserve unrelated keys, nested language
  settings, JSON comments, shortcuts, icons, accents and extension choices.
  Full replacement is a separate operation requiring that explicit scope.
- Export or back up affected resources privately before mutation. Use VS Code's
  UI or supported CLI where available. For an authorized direct file edit,
  protect against concurrent writes, recheck the previewed content and write
  atomically. If VS Code or Sync overwrites the result, stop and resolve the
  writer instead of repeatedly replacing the file.
- Install extensions only in the selected existing profiles. Optional recipe
  entries require selection; do not enable all-profile sharing for a specialist.
  Preserve other extensions unless removal is part of the request.

The [profile helper](../project/docs/shared/tools/vscode-profiles.md) can generate
review exports, install selected extensions, or explicitly replace and restore
complete settings and shortcuts. Its replacement mode is unsuitable for a small
merge. Inspect its preview and keep output outside the installed skill. The
manual route uses the editor guide without helpers.

## Verify and recover

Re-read the changed settings and profile extension inventory. Compare untouched
resources with the backup, then perform the requested feature's functional check.
Separate file/CLI verification from a check inside the running editor. Report any
remaining reload, sign-in or remote-extension installation step.

Dependency dashboards may run install commands or produce AI update prompts.
Configuring one does not authorize project dependency changes. Use the repository's
framework migration process when a separate update task is requested.

For recovery, preview the exact backup and check for edits made since the change.
Restore only the selected resources; merge newer work before replacing a file.
Do not delete the entire Code user folder, profile storage, extension directory or
Sync data to fix one setting. Profile removal, extension removal and application
uninstallation are distinct requests.

Report the profiles changed, keys/extensions affected, backup location and checks
performed. Keep live paths and extension inventories outside the public source.
When repository updates are requested, edit the canonical configuration and guide,
then regenerate references and packages through the contribution workflow.
