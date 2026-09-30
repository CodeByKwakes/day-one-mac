[← Manual handbook](README.md) · [Phase 4](../01-required/04-core-tools-and-hosting.md)

# Developer folders and optional ghq

Choose where future projects go, without moving today's projects. This guide
works with or without Day One Mac, chezmoi, a hosting account, or a shell theme.
Creating folders does not require Git identity or authentication. Cloning a
private repository later does require access to that repository.

## Choose a layout

Every option creates or reuses `~/Developer`. Existing contents are preserved.
The hosting track (GitHub, Azure, or both) is a separate decision.

| Choice | What is created | Where selected ghq places new clones | Best fit |
|---|---|---|---|
| No predefined layout (`none`) | `~/Developer` only | `~/Developer/<host>/<owner>/<repo>` | Decide your organisation later |
| Repository-oriented (`repository`) | `~/Developer` only; host/owner folders appear when cloning | `~/Developer/<host>/<owner>/<repo>` | Mostly repository-based work |
| Purpose-oriented (`purpose`) | `Projects`, `Sandbox`, `Resources`, `Archive` inside `~/Developer` | `~/Developer/Projects/<host>/<owner>/<repo>` | Separate active projects, experiments and reference material |
| Keep existing (`existing`) | No template; reuse `~/Developer`, or create it if missing | Your confirmed existing primary root; other roots remain intact | Established or multi-root setups |

The first two options intentionally create the same directory. One makes no
organisation recommendation; the other adopts a repository naming convention.
ghq itself always uses its host/path convention, even with **No predefined layout**.

For the purpose-oriented layout:

- **Projects:** active source repositories; keep related source and project files together.
- **Sandbox:** experiments you have deliberately classified as temporary. Nothing is automatically deleted.
- **Resources:** reference repositories, examples, and reusable learning material.
- **Archive:** inactive work you intentionally retain. Moving a project here is a separate manual decision.

Old numbered folders, `_sandbox`, `_archive`, and projects outside Developer
remain valid. Selecting another layout creates missing folders for future work;
it is not a migration. A selected ghq does not sort repositories among these
categories. Its new clones go to the single selected primary root.

## Fully manual walkthrough

This section uses only the shell, Git, Homebrew and optionally chezmoi/ghq.
You do not need to install or invoke Day One Mac.

### 1. Inspect before creating folders

Use Finder's **Go → Home** to inspect `Developer`, or run:

```bash
ls -ld "$HOME/Developer"
```

“No such file or directory” means it is absent. If it is a file or a symlink,
stop and decide what owns that location; do not replace it blindly. Inspect
existing folders before choosing **Purpose-oriented**, too.

For any layout, create the top-level directory if absent:

```bash
mkdir -p "$HOME/Developer"
```

Only for **Purpose-oriented**, add:

```bash
mkdir -p "$HOME/Developer/Projects" "$HOME/Developer/Sandbox" \
  "$HOME/Developer/Resources" "$HOME/Developer/Archive"
```

Other choices need no template directories. Repository-oriented placement can
also be followed with ordinary `git clone` and an explicitly chosen destination.

### 2. Decide whether you want ghq

ghq is a repository locator/cloner, not a Git replacement, backup system, or
mandatory development tool. Skip the rest of this subsection if you do not want
it. Do not uninstall or reconfigure an existing copy merely because you skip it.

Check whether it is already available:

```bash
command -v ghq
```

If missing and you choose it, first complete the manual
[Git/Homebrew foundation](../20-reference/MANUAL-SETUP-GUIDE.md),
then install only ghq:

```bash
brew install ghq
```

Review current routing **before writing configuration**:

```bash
ghq root
ghq root --all
git config --show-origin --get-regexp '^ghq\.'
printenv GHQ_ROOT
```

The last two commands may return no output when unset. `GHQ_ROOT` overrides
configured roots. Multiple `ghq.root` values are supported; the last is primary.
Run these inspections outside a Git repository (for example, after `cd /`) to
avoid confusing project-local overrides with the machine-wide default. The CLI
does its root checks in that neutral context.
URL-specific roots and Git includes can add routing rules. **Keep existing**
means preserving this configuration, not replacing it with one value. Record
the output of `ghq root` as the primary root you expect. Check external drives
are mounted before relying on their repositories.

For a new, unconfigured setup, choose **one** root:

```bash
repo_root="$HOME/Developer"          # none or repository
# For purpose-oriented instead:
# repo_root="$HOME/Developer/Projects"
```

If `.gitconfig` is **not managed by chezmoi or another system**, and no existing
ghq/include/environment rules need preserving, configure it directly:

```bash
git config --global ghq.root "$repo_root"
```

If **chezmoi already manages `.gitconfig`**, edit its source instead:

```bash
chezmoi edit "$HOME/.gitconfig"
```

Add the selected absolute root to the appropriate `[ghq]` section. For example,
`root = /Users/your-name/Developer/Projects` for purpose-oriented placement.
Use your actual home path, preserve other entries, and keep machine-specific
paths in a template if sharing dotfiles between Macs. Then review and apply only
that target:

```bash
chezmoi diff "$HOME/.gitconfig"
chezmoi apply "$HOME/.gitconfig"
```

Choosing chezmoi later does not change the folder layout. You may add the reviewed
`.gitconfig` to its source at that point. The
[chezmoi guide](chezmoi.md) covers local-only versus private-repository storage;
neither requires a different folder walkthrough.

### 3. Verify and use the result

Use Finder or `ls -ld` to confirm just the directories you selected. If ghq was
selected, check both its primary root and all roots again:

```bash
ghq root
ghq root --all
ghq list -p
```

`ghq list -p` prints absolute paths across roots; empty output is normal before
you have any repositories. To clone later, substitute a repository you actually
want in `ghq get github.com/OWNER/REPOSITORY`. It creates the host/owner hierarchy
under the primary root. Review provider-specific Azure paths before assuming a
destination. Never use `ghq migrate` as part of this setup: it moves repositories.

## CLI-assisted equivalent

Open this guide with `day-one-mac docs folders --browser`; the handbook export
also includes it for offline reading or printing.

The standalone folder command does not run other setup phases. A folders-only
example selects no installation:

```bash
day-one-mac folders --plan --layout purpose --ghq no
day-one-mac folders --apply --layout purpose --ghq no
day-one-mac folders --check
day-one-mac folders --resume
```

To opt into ghq, plan with `--ghq yes`. If it is missing, approve its Homebrew
installation separately with `--install-ghq` on **apply or resume**. Homebrew and Git must
already be available; this command does not bootstrap prerequisites. A compatible
existing ghq is reused and not recorded as an installation owned by Day One Mac.

For an established setup, inspect `ghq root --all`, then supply the actual
primary root rather than copying this example unchanged:

```bash
day-one-mac folders --plan --layout existing --ghq yes \
  --ghq-root "$HOME/Developer/Projects"
```

Use the same choices with `--apply` after reviewing the plan. No roots are
rewritten in **Keep existing**. With ghq disabled, omit `--ghq-root`.

The main wizard offers these same four layouts and a separate ghq choice,
defaulting ghq to **No**. Direct setup accepts `--layout`, `--ghq`, and optionally
`--ghq-root`; there, selecting ghq also authorizes its missing package installation
in the Installation Centre. Phase 4 delegates to the shared folder capability.
Phase 5 requires ghq in the clean shell only when selected, and Phase 8 checks
the selected layout/root rather than a hardcoded path.

## Safety, state and recovery reference

- **Plan/check:** read-only; no state writes, package installation, source apply,
  login, clone, or completion claim. An unresolved conflict returns non-zero.
- **Apply:** explicit approval; inspects path and root conflicts first. It saves
  intent before execution, journals only new directories/new installations and
  backs up an unmanaged Git config before adding a previously absent root.
- **Resume:** uses saved choices and reruns live checks/creation idempotently.
  It never treats an old phase marker as proof of the new choices. Change choices
  with plan/apply, not resume.
- **Records:** `folder-layout`, `ghq-choice`, and `folder-ghq-root` live in the
  existing private setup state alongside the install/path manifests. Saved
  choices are intent, not evidence that an interrupted apply finished.
  If choice saving itself was interrupted, `ghq-choice` remains `pending` and
  resume refuses to guess. Review and supply all choices again with plan/apply.
- **Conflicts:** files or symlinks at template paths stop creation. Existing
  ghq roots, Git includes, XDG Git configuration, environment overrides, or
  evidence of a chezmoi source/configuration stop a proposed root write for manual review. Matching
  effective roots need no write, regardless of their owner.
  An existing default `~/ghq` directory also needs review before changing roots;
  leaving it behind silently could hide repositories from later discovery.
  The ownership check is deliberately conservative: it does not run chezmoi or
  render templates to decide whether `.gitconfig` is managed. If it is unmanaged,
  review and set the root yourself; a matching rerun needs no further write.
- **Exit codes:** `0` successful bounded action; `2` missing/invalid choices;
  `10` manual review/prerequisite; `11` failed local check.

Resolve conflicts in the owning tool, inspect again, then rerun. The pilot does
not convert symlink-based Developer layouts; keep them unchanged and follow the
manual route until you have chosen a physical-path arrangement. Do not delete
folders to satisfy a check. Preview `day-one-mac rollback` if you want to reverse
recorded setup changes; it covers the shared journal, not just this capability.
Existing directories, external roots and repository data are not adopted or
automatically removed. Changing layouts never cleans up the old layout.

The advanced repository audit uses absolute ghq paths only when ghq is selected.
It is not a whole-disk repository inventory. Cleanup remains bounded to its
documented Developer scope and does not acquire authority over external ghq roots.
