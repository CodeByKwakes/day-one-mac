[← Phase 7](07-vscode-base.md) · **Phase 8** · [Optional modules →](../02-optional/09-databases.md)

# Phase 8 — Verify, record, and reproduce

**Time:** 20–40 minutes · **Required:** everyone

## Outcome

The Mac passes a track- and stack-aware audit, installed Homebrew state is
recorded in a Brewfile, the Brewfile is managed by chezmoi, and the dotfiles
source passes the selected protection gate: private Git or local-only. Optional databases, AI, MCP, editor
profiles, and the optional Warp Drive import do not affect this gate. The
Raycast and Warp applications themselves are required, but Homebrew ownership
is not: valid external installations satisfy the same gate.

After the phase passes, use [Finalise or detach Day One Mac](../04-operations/FINALIZE.md) to
compact the retained operational evidence or deliberately detach the portable
command and state. Finalisation is optional and never uninstalls the completed
environment.

If this is your first chezmoi setup, the
[complete chezmoi tutorial](../20-reference/CHEZMOI-SETUP-TUTORIAL.md) connects
the Phase 5 source and target work to this phase's Brewfile, secret scan,
private-Git, and local-only protection gates.

## How to use this phase

- **Manual route:** complete
  [Manual 8](../20-reference/NOTION-SETUP-GUIDE.md#manual-8--record-and-verify-the-finished-environment)
  and retain your own verification record. The manual route has no runner
  ownership manifest or phase marker.
- **Script-assisted route:** run `day-one-mac setup --phase 08`. The runner performs Step 8.1,
writes the machine report, records the Brewfile, and checks the chosen dotfiles
mode. Private-Git mode verifies the remote and pushed branch. Local-only mode
secret-scans the source and records that remote recovery is intentionally absent.

## Step 8.1 — Validate the project

The Phase 8 runner performs this validation before auditing the Mac. Run it
directly only when diagnosing the project or checking a change without running
the machine audit:

```bash
day-one-mac validate
```

This checks shell syntax, required documents, internal paths, cleanup safety
markers, and the regression fixtures. It needs `ripgrep`, which the
Installation Centre already installed; it stops rather than skipping checks if
`rg` is missing. Fix a project validation failure before trusting the setup
report.

Contributors changing the scripts can also run the ShellCheck linter. It is a
separate, optional tool and is not needed to complete any phase:

```bash
brew install shellcheck
cd "$(day-one-mac root)"
./scripts/lint.sh
```

Expected result:

```text
✓ ShellCheck reported no findings in 59 scripts.
```

The reviewed list of disabled checks, and the reason each one is disabled,
lives in `.shellcheckrc`. Both `lint.sh` and `validate.sh` also run in CI on
every pull request.

## Step 8.2 — Run the complete Phase 8 gate

```bash
day-one-mac setup --phase 08
```

The report is written to:

```text
~/.day-one-mac/verification.md
```

It records pass/fail results for:

- Native Apple-silicon execution, Xcode or Command Line Tools readiness, and
  Homebrew at the Apple-silicon `/opt/homebrew` prefix.
- Git identity, the `ghq` repository root, chezmoi, Starship, Raycast, Warp,
  and the VS Code CLI.
- The ownership source of every required catalogue item: 1Password, its CLI,
  Raycast, VS Code, Warp, and JetBrains Mono Nerd Font.
- The portable `day-one-mac` dispatcher and its recorded runtime root.
- The optional advanced-module tracker and read-only extended-audit entry point.
- FileVault.
- Gatekeeper remains enabled.
- Node, npm, and pnpm when Node was selected.
- uv-managed Python when Python was selected.
- GitHub authentication on Tracks 1 and 3.
- Azure authentication on Tracks 2 and 3.
- Brewfile management and a basic dotfiles secret-pattern scan.
- In private-Git mode, a clean source, pushed upstream branch, and reachable
  private GitHub or Azure DevOps origin matching the selected track.
- In local-only mode, a readable secret-scanned source with no Git or remote
  requirement and an explicit encrypted-backup warning. Pre-existing `.git`
  metadata is reported and preserved rather than deleted.

Open the report and investigate every failure. Either read it in the terminal:

```bash
cat "$HOME/.day-one-mac/verification.md"
```

or open it in TextEdit:

```bash
open -e "$HOME/.day-one-mac/verification.md"
```

It is a Markdown table; every row ending in `FAIL` or `REVIEW` needs attention.

Installed software is not enough; the command must work in the environment
where it will be used.

The application ownership detail is also written to:

```text
~/.day-one-mac/application-provenance.md
```

An external or Mac App Store result is a pass. It means that the app remains
the responsibility of Company Portal, the App Store, or its existing installer.

## Step 8.3 — Record Homebrew desired state

After the audit passes, the runner creates `~/Brewfile` only when it is absent:

```bash
brew bundle dump --file="$HOME/Brewfile"
```

It deliberately does not use `--force`. If a Brewfile already exists, review
it rather than overwriting it.

Inspect the generated file:

```bash
cat ~/Brewfile
brew bundle check --file="$HOME/Brewfile" --no-upgrade
```

`brew bundle check` prints `The Brewfile's dependencies are satisfied.` when
everything listed is installed.

Remove accidental packages only after deciding they are not desired state.
Never place tokens, private taps with embedded credentials, or environment
secrets in a Brewfile.

The runner adds a newly created Brewfile to chezmoi:

```bash
chezmoi add "$HOME/Brewfile"
chezmoi source-path "$HOME/Brewfile"
chezmoi diff
```

If a pre-existing Brewfile is not managed, the runner pauses so you can review
and add it yourself.

## Step 8.4 — Inspect the complete dotfiles source

```bash
SOURCE="$(chezmoi source-path)"
cd "$SOURCE"
git status --short 2>/dev/null || true
find . -maxdepth 5 -type f -print | sort
```

Review at least:

- The source forms of `.zprofile`, `.zshrc`, `.config/zsh/path.zsh`,
  `.config/zsh/aliases.zsh`, `.gitconfig`, and `.ssh/config`.
- `starship.toml`.
- The Brewfile.
- `.chezmoiignore` if present.
- Any template for accidental literal email addresses, tokens, or private keys.

Search for obvious secret shapes without printing secret values into a shared
log:

```bash
rg -l --hidden --no-ignore -g '!.git/**' \
  -e 'BEGIN .*PRIVATE KEY' \
  -e 'ghp_' -e 'github_pat_' -e 'AKIA' -e 'Bearer[[:space:]]' \
  . || true
```

`--hidden` and `--no-ignore` matter here: without them ripgrep skips dot-files
and anything listed in `.gitignore`, which is exactly where a stray credential
is most likely to sit. Each pattern needs its own `-e` because ripgrep accepts
only one positional pattern. Always use `-e` for a pattern that begins with `-`,
such as `-----BEGIN`, or ripgrep will read it as a command-line flag.

No output means nothing matched. Treat every match as a review item; some
documentation examples can be false positives.

## Step 8.5 — Complete the selected dotfiles protection

### Private-Git mode

The runner cannot create a remote repository without your choice of account,
owner, and repository name. On a new setup, its first Phase 8 attempt therefore
creates or records the Brewfile and then pauses with this as the next action.
Complete the matching provider route below and rerun Phase 8.

If the source is not already a Git repository:

```bash
cd "$(chezmoi source-path)"
git init
git branch -M main
```

Commit only after the secret review:

```bash
git add --all
git status --short
git commit -m "chore: bootstrap day one dotfiles"
```

### Tracks 1 and 3 — GitHub private remote

Create a private empty repository in GitHub, then either add its SSH URL:

```bash
git remote add origin git@github.com:<account>/<dotfiles-repository>.git
git push -u origin main
```

Or use GitHub CLI from the source directory:

```bash
gh repo create <dotfiles-repository> --private --source=. --remote=origin --push
```

### Track 2, or Track 3 work source — Azure DevOps private remote 🏢

Create an empty private Azure Repository, copy its SSH URL, then run:

```bash
git remote add origin <azure-ssh-url>
git push -u origin main
```

Do not publish dotfiles to a public remote merely because the current files
look harmless. Future changes may contain machine-specific data.

On rerun, the script confirms GitHub visibility through `gh`. For Azure
DevOps, it confirms that the containing project is private through `az`. It
also checks that `origin` is reachable and that the current branch has a pushed
upstream. A self-hosted or differently named remote is left as a manual review
instead of being guessed.

Command references: [GitHub CLI `gh repo view`](https://cli.github.com/manual/gh_repo_view)
and [Azure DevOps `az devops project show`](https://learn.microsoft.com/azure/devops/organizations/projects/create-project?view=azure-devops&tabs=browser#show-project-information-in-the-web-portal).

### Local-only mode

No Git repository, remote, commit, or push is required. Choose this from the
wizard or directly:

```bash
day-one-mac setup --phase 05 --local-dotfiles
day-one-mac setup --phase 08
```

Phase 8 still verifies that the source exists, that the Brewfile is managed,
and that the secret-pattern scan passes. It writes `local-only selected` into
the verification report. Back up this directory because no remote can recover it:

```text
~/.local/share/chezmoi
```

Changing the saved mode does not delete an existing `.git` directory. Review
and archive old repository metadata yourself before removing it.

## Step 8.6 — Reproduction procedure

The shortest safe private-Git rebuild on another clean Mac is:

```bash
# Install Command Line Tools and Homebrew first.
brew install chezmoi
chezmoi init <private-dotfiles-remote>
chezmoi diff
chezmoi apply
brew bundle install --file="$(chezmoi source-path)/Brewfile"
```

Then rerun this project's track-aware authentication and verification phases.
Do not apply a source before reviewing its diff on the new machine.

For local-only mode, restore the backed-up chezmoi source to
`~/.local/share/chezmoi`, run `chezmoi diff`, and apply only after
review. Without that backup there is no automatic rebuild source.

## Step 8.7 — Understand cleanup before declaring completion

Two preview-first commands are included:

```bash
# Broad: all Homebrew packages/apps plus known development configuration.
day-one-mac clean

# Narrow: only packages and paths recorded as changed by this runner.
day-one-mac rollback
```

Both commands default to read-only previews. Read [ROLLBACK.md](../04-operations/ROLLBACK.md)
before adding `--execute`.

## Step 8.8 — Compare the completed layout

Review [EXPECTED-LAYOUT.md](../20-reference/EXPECTED-LAYOUT.md) after the machine audit. It
records the standalone runtime, optional contributor source checkout, `ghq`
project layout, required applications, Homebrew prefix, chezmoi source, shell
configuration, toolchain data, and private `~/.day-one-mac` evidence.

Do not move a path merely to make the tree look identical. Confirm dynamic
locations with `brew --prefix`, `chezmoi source-path`, `pnpm store path`, and
`uv python dir`; then investigate only meaningful ownership or safety drift.

## Troubleshooting

| Symptom | Resolution |
|---|---|
| The verification report contains one failure | Return to the named owning phase; do not mark Phase 8 complete manually |
| A required app passes but is absent from the Brewfile | Check `application-provenance.md`; external applications correctly remain outside Homebrew desired state |
| `brew bundle dump` says the Brewfile exists | Review and preserve it; the runner intentionally refuses overwrite |
| `chezmoi add ~/Brewfile` includes unexpected edits | Inspect `chezmoi diff` and apply only reviewed targets |
| Git push reports `Permission denied (publickey)` | Unlock 1Password, verify `ssh-add -l`, then repeat the provider SSH test from Phase 4 |
| The dotfiles repository is public | Change repository visibility before pushing machine configuration |
| Local-only mode reports no remote | This is expected; verify the chezmoi source is included in an encrypted backup |
| Secret scanning finds a credential | Remove it from source and Git history, then rotate the credential before pushing |

## Phase 8 completion checklist 🚦

- [ ] The project validator run by Phase 8 passes.
- [ ] The machine verification report contains no failed gate.
- [ ] `ghq root` reports the intended `~/Developer` root.
- [ ] `day-one-mac runtime-status` reports `standalone runtime` and `Integrity: verified`.
- [ ] `day-one-mac root` reports the active versioned runtime (or the intentional linked source for contributors).
- [ ] `day-one-mac finalize --help` confirms that post-setup record
      finalisation is available.
- [ ] `day-one-mac advanced --list` and `day-one-mac advanced-audit --help` succeed.
- [ ] The application provenance report shows every required app as ready and identifies its installation source.
- [ ] The completed machine agrees with `EXPECTED-LAYOUT.md` or documented dynamic paths.
- [ ] `~/Brewfile` contains only intended Homebrew desired state.
- [ ] The Brewfile and required dotfiles are managed by chezmoi.
- [ ] `chezmoi diff` is empty or every VS Code comparison is understood.
- [ ] The source is clean and the secret-pattern scan has no review items.
- [ ] Private-Git mode has a private, reachable, pushed remote; or local-only
      mode is recorded and the source has an encrypted backup plan.
- [ ] A new login shell finds the selected tools.
- [ ] The cleanup boundaries in `ROLLBACK.md` are understood.

The required day-one-mac environment is complete. Continue only with optional
modules that a real project needs.

---

[← Phase 7](07-vscode-base.md) · [Expected layout](../20-reference/EXPECTED-LAYOUT.md) · [Add databases (optional) →](../02-optional/09-databases.md) · [Project home](../README.md)
