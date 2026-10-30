# On-demand workspace restore tool

The optional [workspace helper](../../../helpers/workspaces/workspace.cjs) saves
calibrated display arguments as private JSON data, previews changes and requests
an existing Raycast layout after display verification. It has no daemon, login
item or setup-manager state. Follow the [manual guide](../../setup/manual/apps/workspaces.md)
for the actual desk layout, app ownership, prerequisites and visual checks.

## Prerequisites and installation scope

Use Node.js 22.20+, an approved `displayplacer` installation and Raycast's named
layout feature. Calibrate displays manually first. This parser accepts persistent
UUIDs, explicit resolution/refresh/color/scaling/origin/rotation fields and
separate enabled displays. If a driver reports no refresh rate and omits `hz`,
the helper stops with `Missing display field: hz`; use manual arrangement rather
than guessing a rate. The parser follows the
[displayplacer 1.4.0 output](https://github.com/jakehilborn/displayplacer/blob/v1.4.0/src/DisplayPlacer.c);
check that contract after upgrading. It deliberately rejects mirrored/disabled screens,
mode-only commands and unfamiliar output rather than guessing.

An installed skill contains the source under
`references/project/helpers/workspaces/workspace.cjs`. It needs no other files
from the package. Inspect that source before copying it to a private tools folder.
For example, from the installed skill directory:

```bash
umask 077
mkdir -p "$HOME/.local/lib/day-one-workspace"
cp -n references/project/helpers/workspaces/workspace.cjs "$HOME/.local/lib/day-one-workspace/workspace.cjs"
node "$HOME/.local/lib/day-one-workspace/workspace.cjs" --help
```

Expected result: help output, without display mutations. `cp -n` preserves an
existing copy: compare it before approving an update, and retain the prior
source privately. A source checkout can supply the same single file from
`helpers/workspaces/workspace.cjs`; no permanent checkout is needed.

Commands below run from the copied file's directory:

```bash
cd "$HOME/.local/lib/day-one-workspace"
```

Private presets default to `~/.config/workspace-layouts`. Use
`DAY_ONE_WORKSPACE_DIR` for a different private location. Symlinked user paths,
foreign-owned files and group/world-readable preset directories/files are
refused. Do not use an installed skill, source checkout, shared folder or cloud
sync directory for machine-specific calibration.

## Command reference

| Command | Purpose | Writes or effects |
|---|---|---|
| `--help` | Show usage | None |
| `inspect` | Read three consecutive equal display samples | None |
| `capture NAME LAYOUT BUILTIN_UUID` | Save the current known-good desk and named Raycast layout | New private JSON preset; never overwrites |
| `detect` | Find exactly one preset for the current display-ID set | None; stops on zero or multiple matches |
| `preview NAME` | Show current/proposed arguments and approval token | None |
| `apply NAME TOKEN` | Apply an unchanged reviewed preview | Private recovery snapshot, display change, Raycast request |
| `run NAME` | Preview, ask through a macOS dialog, then apply | Same as apply after confirmation |
| `run auto` | Detect a sole preset, confirm, apply | Same; choose by name if activities share a desk |
| `preview recovery:UUID` | Review a saved display-only recovery | None |
| `apply recovery:UUID TOKEN` | Restore that display snapshot | New recovery snapshot and display change; no Raycast request |

A sample can take up to 12 reads, one second apart. Invalid output stops
immediately; connection/driver readiness is not inferred from a quiet log.
Every external process has a 30-second timeout. A successful layout URL request
is not app-window verification. Raycast can launch apps configured in its layout.

## Capture and review

1. At the calibrated desk, run:

   ```bash
   node workspace.cjs inspect
   ```

   Expected result: display argument strings. Identify the built-in display UUID
   by running `displayplacer list`: use the persistent UUID in the block marked
   `Type: MacBook built in screen`, then physically confirm the MacBook. The
   helper does not infer it from an external-screen count.

2. Capture with your real UUID in place of the example placeholder:

   ```bash
   node workspace.cjs capture Office-Code Office-Code BUILTIN_UUID
   ```

   Expected result: a new `Office-Code.json`, directory mode `700`, file mode
   `600`. The tool never verifies that a Raycast layout name exists; test that
   layout separately. Use a new preset name for recalibration, preserving old data.

3. Review the proposed operation:

   ```bash
   node workspace.cjs preview Office-Code
   ```

   Expected result: JSON with `preset`, `current` and `token`. Check every display
   and the layout name. Treat the token as approval for that exact preview,
   not a credential or permanent permission.

4. Apply the exact token from your preview:

   ```bash
   node workspace.cjs apply Office-Code TOKEN_FROM_PREVIEW
   ```

   Expected result: private recovery path, verified display values and a Raycast
   layout request. Any change to the preset or current display values requires
   a fresh preview. Run the manual guide's visual verification afterward.

The tool checks the entire persistent-ID set. A missing/changed monitor, closed
laptop, duplicate ID or unsupported argument stops restoration. It does not
change VS Code profiles, repositories, working directories or database sessions.
Raycast itself must be configured not to close unrelated windows, with
**Other Windows: None**. Ambiguous editor windows remain a manual selection.

## Add a single Raycast entry point

After testing capture and preview, create a Script Command with Raycast's
**Create Script Command** action. Save it in your chosen Script Commands folder
and replace its body with this Bash 3.2-compatible wrapper:

```bash
#!/bin/bash
# @raycast.schemaVersion 1
# @raycast.title Restore Developer Workspace
# @raycast.mode fullOutput
# @raycast.packageName Developer Workspace
# @raycast.argument1 {"type":"text","placeholder":"Preset name or auto"}
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
exec node "$HOME/.local/lib/day-one-workspace/workspace.cjs" run "${1:-auto}"
```

Make the selected script executable and register its directory through
**Raycast Settings → Extensions → Script Commands → Add Script Directory**.
If Node is owned by fnm, Raycast may not have it on PATH: replace `node` with the
explicit executable returned by `command -v node` in your working terminal.
Do not source `.zshrc` inside a launcher. Review that path after Node upgrades.

Run with a selected preset, inspect the confirmation and choose **Restore**.
**Cancel** makes no display change. `auto` works only when one preset matches;
`Office-Code` and `Office-Data` require explicit activity selection. Prefer a
Root Search alias; optionally assign the conflict-checked hotkey in the manual
guide. No monitor-connect or sleep/wake watcher is installed.

## Recovery, update and removal

Before each display mutation, the helper exclusively publishes a complete
`recovery/UUID.json` snapshot. Backups are never pruned. If a command fails after
changing displays, inspect the current state; do not blindly retry or run an
automatic rollback against a different topology.

Use the printed UUID to preview and approve display-only recovery:

```bash
node workspace.cjs preview recovery:UUID_FROM_RECOVERY_FILENAME
node workspace.cjs apply recovery:UUID_FROM_RECOVERY_FILENAME TOKEN_FROM_PREVIEW
```

Expected result: the prior display values return for that same connected desk.
App-window positions are not restored by the recovery file. Use System Settings
if displayplacer cannot restore them.

A lock prevents concurrent capture/apply operations. If the process is killed,
`.lock` may remain: confirm no restore is running, inspect recovery evidence,
then remove only that empty lock directory with `rmdir`. Private temporary files
from an interrupted save may remain; preserve and inspect them before cleanup.
A preview does not write or clear locks.

For updates, compare source, keep the previous file, replace only the standalone
copy and rerun preview plus a harmless layout test. For removal, unregister the
selected Raycast entry and archive the standalone tool. Keep calibration and
recovery files unless their deletion is separately requested. No package-manager
or system service uninstall is required.

## Evidence limits

The regression fixtures cover parsing, delayed/missing/duplicate monitors,
explicit activity selection, approval drift, repeated operations, interrupted
execution, recovery, locks and private-path checks. They do not prove DisplayLink
compatibility, live resolution acceptance, Raycast matching, permissions or
correct selection among several VS Code windows. Calibrate and verify Office
and Home separately before relying on restoration.
