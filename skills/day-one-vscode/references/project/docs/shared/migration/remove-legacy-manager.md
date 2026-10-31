# Remove the legacy Day One Mac manager

Current Day One Mac skills and manual guides need no installed manager. Retire
only the old manager and its confirmed integrations. Keep developer applications,
working shell settings, VS Code profiles, databases, source repositories and
private recovery backups unless you separately decide to remove them.

## Prerequisites and assumptions

Use your own account on the affected Mac. On a managed Mac, let IT handle
managed files and installations. This procedure assumes the historical default
locations below; custom locations must be inspected separately. Never reinstall
an old manager merely to uninstall it. Do not run an unknown downloaded uninstaller.

## 1. Inventory without changing anything

Close old setup sessions. In a terminal, inspect command resolution:

```bash
type -a day-one-mac
```

Expected result: zero or more executable, alias or function locations. Absence
is not proof that all old files have gone. Inspect likely locations:

```bash
for legacy_path in \
  "$HOME/.local/bin/day-one-mac" \
  "$HOME/.local/share/day-one-mac" \
  "$HOME/.day-one-mac" \
  "$HOME/.config/day-one-mac"; do
  if [ -e "$legacy_path" ] || [ -L "$legacy_path" ]; then
    ls -ld "$legacy_path"
  fi
done
```

Expected result: paths, ownership and symlink targets, without printing private
configuration contents. Inspect any custom location shown by the launcher.
Search shell files for old command references locally; do not share their raw
contents because shell files can contain secrets:

```bash
rg -n 'day-one-mac|cdayone|DAY_ONE_MAC_' \
  "$HOME/.zshrc" "$HOME/.zprofile" "$HOME/.config/zsh" 2>/dev/null
```

Also inspect Raycast Script Command directories, imported Warp workflows,
Shortcuts, login items and scheduled tasks for references to the exact old
launcher. Do not assume the manager installed a service. Keep direct Git,
Homebrew, chezmoi, application launch and working-directory commands.

The parent `~/.local/share/day-one-mac/` may also hold current versioned plugin
artifacts under `plugins/`. Inspect the selected clients' marketplace sources
using the [plugin lifecycle guide](../../setup/manual/ai/day-one-plugins.md).
Never retire that parent wholesale when a current client uses a child directory.
Select only confirmed legacy children; unknown ownership means leave them in place.

## 2. Agree the removal list

Classify every discovered item before moving it:

| Item | Action |
|---|---|
| Confirmed old launcher and versioned runtime directory | Back up, then retire |
| Old setup state, manifests, exports and profile replacement backups | Preserve privately; archive only after checking recovery needs |
| Shell alias or function calling the old manager | Remove just that definition after backing up the file |
| Runtime-dependent Warp/Raycast/Shortcuts entry | Export or back it up, then remove that entry in the app |
| Zsh settings, Homebrew, applications, VS Code profiles, database data | Keep |
| Source checkout with uncommitted or unpushed work | Keep until its work is independently preserved |
| Installed `day-one-mac` AI skill | Keep; it is independent of the retired command |
| Unknown path or ownership | Leave it for investigation |

Expected result: an explicit approved list, with no broad deletion of `.local`,
`.config`, `.agents`, `.codex`, `.claude` or the home directory.

## 3. Back up the approved files

Create a private retirement folder:

```bash
mkdir -p "$HOME/Backups"
RETIREMENT_BACKUP="$(mktemp -d "$HOME/Backups/day-one-retired.XXXXXX")"
chmod 700 "$RETIREMENT_BACKUP"
printf '%s\n' "$RETIREMENT_BACKUP"
```

Expected result: a unique private location. Record it outside the public repo.
For an approved regular directory, replace the placeholder with the exact
confirmed legacy child directory, then copy it with macOS `ditto`:

```bash
LEGACY_DIRECTORY="/absolute/path/to/confirmed-legacy-directory"
test -d "$LEGACY_DIRECTORY" && test ! -L "$LEGACY_DIRECTORY"
ditto "$LEGACY_DIRECTORY" "$RETIREMENT_BACKUP/runtime-copy"
```

Stop if the prerequisite check fails; inspect the symlink or custom location
instead. Copy state and configuration separately if present, and back up shell
files before editing them. Use `cp -P` for the launcher if it is a symlink, so the
backup preserves the link itself. Keep backups encrypted with your usual method.

Verify directory contents before retirement. With Python 3 installed, this
compares relative paths, file bytes, permission bits and symlink destinations;
it does not follow symlink directories or execute copied code:

```bash
python3 - "$LEGACY_DIRECTORY" "$RETIREMENT_BACKUP/runtime-copy" <<'PY'
import hashlib, os, pathlib, stat, sys

def inventory(root):
    result = {}
    for parent, directories, files in os.walk(root, followlinks=False):
        for name in directories + files:
            p = pathlib.Path(parent) / name
            info = p.lstat()
            key = str(p.relative_to(root))
            if stat.S_ISLNK(info.st_mode):
                value = ('link', os.readlink(p))
            elif stat.S_ISDIR(info.st_mode):
                value = ('directory',)
            elif stat.S_ISREG(info.st_mode):
                h = hashlib.sha256()
                with p.open('rb') as stream:
                    for block in iter(lambda: stream.read(1024 * 1024), b''):
                        h.update(block)
                value = ('file', info.st_size, h.hexdigest())
            else:
                raise SystemExit('Unsupported file type; stop and inspect: ' + key)
            result[key] = (stat.S_IMODE(info.st_mode), value)
    return result

left, right = map(pathlib.Path, sys.argv[1:])
if not left.is_dir() or not right.is_dir() or left.is_symlink() or right.is_symlink():
    raise SystemExit('Expected two regular directories')
if inventory(left) != inventory(right):
    raise SystemExit('Backup differs; do not retire the source')
print('Verified directory content, permissions and link targets')
PY
```

Expected result: the verification message. Separately verify any metadata your
recovery needs, such as extended attributes, using the owning application's
backup procedure. Open a restored sample from state/profile backups. Do not
proceed on a failed or incomplete backup.

## 4. Retire only approved items

After approving the exact paths and verifying their backups, move the old
runtime into the retirement folder instead of deleting it:

```bash
test ! -e "$RETIREMENT_BACKUP/retired-runtime"
mv "$LEGACY_DIRECTORY" "$RETIREMENT_BACKUP/retired-runtime"
```

Expected result: the old runtime location is absent and the private original is
recoverable. Run the checks as separate steps and stop on failure. Move the
confirmed old launcher to its own unused retirement name. Archive old state
only after preserving and locating every recovery record you still need.
Do not remove developer tools or volumes created during earlier setup.

Remove only the backed-up shell definitions that reference the old command.
Remove confirmed manager-dependent entries in Warp, Raycast and Shortcuts using
those apps' interfaces. Preserve direct native-tool entries and client settings.

## 5. Verify the Mac still works

Open a fresh terminal and run:

```bash
type -a day-one-mac
node --version
git --version
code --version
```

Expected result: the old command is no longer resolved; the tools you use still
work. Missing optional tools are not a reason to install them during cleanup.
Open VS Code and confirm profiles, settings and extensions. Check your shell
prompt and history search. Open representative projects and verify the selected
container engine without deleting or recreating containers.

Record which files moved, which integrations changed, which checks passed and
which paths were deliberately kept. Retain backups until you no longer need
old ownership or recovery evidence. Updating the AI skill is a separate action.

## Recovery

If a required workflow broke, inspect the backed-up definition before restoring
it. Restore only the exact affected file or item; avoid overwriting later edits.
For a runtime restoration, check that its original directory and launcher names
are unused before moving the archived originals back. Do not restart old setup
or upgrade operations merely to test restoration.

## Prompt for another Mac

```text
Review this Mac for the legacy Day One Mac setup manager. Start read-only.
Use the current remove-legacy-manager guide from the reviewed Day One Mac skill
or repository. Identify the actual launcher, runtime, state, recovery records,
shell aliases and runtime-dependent Warp, Raycast or Shortcuts entries.

Show the exact proposed removal list and wait for my approval. Preserve my
applications, Homebrew, shell setup, VS Code profiles, databases, source work,
installed AI skills and all backups. Do not reinstall the old manager or run an
unknown uninstaller. Do not expose secrets or private inventories.

After approval, make and verify a private recovery copy, then archive only the
approved manager-owned items. Keep unknown items. Verify a fresh terminal,
profiles and developer tools, and give me the backup path and recovery steps.
Never erase disks or delete broad configuration directories.
```
