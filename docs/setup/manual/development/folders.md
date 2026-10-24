[← Manual handbook](../README.md) · [Phase 4](../../assisted/04-core-tools-and-hosting.md)

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
- **Resources:** supporting project material, shared assets, datasets, templates,
  reference material, standalone scripts and VS Code, Warp and Raycast exports.
- **Archive:** inactive work you intentionally retain. Moving a project here is a separate manual decision.

The purpose-oriented setup also creates this Resources structure:

```text
~/Developer/Resources/
├── README.md
├── Project-Materials/
├── Shared-Assets/
├── Datasets/
├── Templates/
├── Reference/
├── Scripts/
├── VSCode/
├── Warp/
└── Raycast/
```

The [Resources README](resources.md) explains
each folder, lists the app subfolders and shows
`Project-Materials/<project>/assets`, `csv`, `exports` and `database-backups`.
Setup creates the VS Code, Warp and Raycast subfolders listed there, and
`Archive/Projects`, `Archive/Experiments`, `Archive/Project-Materials` and
`Archive/Exports`. App folders hold exports and reusable files; setup does not
change applications' active configuration locations or import settings.
Create per-project subfolders when needed. Keep files required to build or run
a project in its repository; use Resources for supporting material kept outside
Git. Setup creates the README only if absent and preserves any existing copy.

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
for folder in Project-Materials Shared-Assets Datasets Templates Reference Scripts VSCode Warp Raycast; do
  mkdir -p "$HOME/Developer/Resources/$folder"
done
for folder in Settings Profiles Extensions Snippets Themes Workspaces; do
  mkdir -p "$HOME/Developer/Resources/VSCode/$folder"
done
for folder in Themes Workflows Launch-Configurations Exports; do
  mkdir -p "$HOME/Developer/Resources/Warp/$folder"
done
for folder in Script-Commands Quicklinks Snippets Exports; do
  mkdir -p "$HOME/Developer/Resources/Raycast/$folder"
done
for folder in Projects Experiments Project-Materials Exports; do
  mkdir -p "$HOME/Developer/Archive/$folder"
done
```

Save the [Resources README](resources.md) as
`~/Developer/Resources/README.md` if you want the guide locally. Review an
existing README before merging any guidance into it.

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
[Git/Homebrew foundation](../README.md),
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
[chezmoi guide](../shell/README.md) covers local-only versus private-repository storage;
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

For Azure Repos Git, use the [clone and update walkthrough](../git/multiple-identities.md#clone-one-azure-repository-and-update-it-later),
which covers both optional ghq and ordinary Git. Folder setup does not clone
repositories or prove provider access. For Azure HTTPS URLs, use
`ghq get --vcs git 'https://dev.azure.com/ORG/PROJECT/_git/REPO'` to bypass VCS
detection. The track-aware persistent defaults are configured separately in
[Phase 4](../../assisted/04-core-tools-and-hosting.md#step-43--configure-global-git-defaults).
Keep notes separate and use
[manual Second Brain links](../second-brain/README.md#link-a-repository-without-syncing-its-contents).

## CLI-assisted equivalent

The [assisted folder operation](../../assisted/04-core-tools-and-hosting.md) is
a separate route. The manual steps above are complete without it.
