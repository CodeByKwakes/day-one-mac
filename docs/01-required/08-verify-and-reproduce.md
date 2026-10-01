[← Phase 7](07-vscode-base.md) · **Phase 8** · [Optional modules →](../02-optional/09-databases.md)

# Phase 8 — Verify, record, and reproduce

**Time:** 20–40 minutes · **Required:** everyone

## Outcome

The Mac passes a track- and stack-aware audit, installed Homebrew state is
recorded in a Brewfile, and configuration follows the selected owner. With
chezmoi, the Brewfile is adopted and the source passes its private-Git or
local-only checks. Without chezmoi, the Brewfile stays user-owned and source
and remote checks are not selected; include configuration in a tested backup.
Starship is checked only when selected, and the login shell must match the
chosen zsh. Optional databases, AI, MCP, editor
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
  [Manual 8](../20-reference/MANUAL-SETUP-GUIDE.md#manual-8--record-and-verify-the-finished-environment)
  and retain your own verification record. The manual route has no runner
  ownership manifest or phase marker.
- **Script-assisted route:** run `day-one-mac setup --phase 08`. The runner performs Step 8.1,
writes the machine report, records the Brewfile, and checks the chosen dotfiles
mode. Private-Git mode verifies the remote and pushed branch. Local-only mode
secret-scans the source and records that remote recovery is intentionally absent.
Unmanaged mode neither invokes chezmoi nor claims a verified backup. It reports
unselected components separately from successful checks. In the steps below,
skip chezmoi commands and source/remote sections when unmanaged mode is selected.

## Step 8.1 — Validate the project

Phase 8 now verifies the installed runtime, not the contributor test suite.
Run this read-only check independently when diagnosing an installation:

```bash
day-one-mac verify
```

It verifies packaged file checksums and shell syntax. Missing or modified
runtime files stop verification. A linked checkout explicitly reports that it
has no packaged integrity manifest. Runtime checks do not prove that every
application or account is configured; the next step audits the machine.

The standalone runtime does not ship repository tests or contributor tooling.
Contributors run `scripts/validate.sh` and `pnpm run lint` from their source
checkout; see [Contributor tooling](../CONTRIBUTOR-TOOLING.md). The old
`day-one-mac validate` command is an alias for `verify` in installed runtimes.

With the core preset, VS Code and the omitted desktop applications are not
verification gates. Authentication, chosen languages, and dotfiles checks
remain mandatory.

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
- Git identity, selected developer folders and optional `ghq` root, chezmoi, Starship, Raycast, Warp,
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

It is a Markdown table; every `FAIL` or pending `REVIEW` row needs attention.

Installed software is not enough; the command must work in the environment
where it will be used.

The application ownership detail is also written to:

```text
~/.day-one-mac/application-provenance.md
```

An external or Mac App Store result is a pass. It means that the app remains
the responsibility of Company Portal, the App Store, or its existing installer.

### SSH authentication and existing key storage

These are separate checks. Selecting 1Password changes the intended Git
authentication route; it does not grant permission to delete earlier keys.

For SSH modes, Phase 8 tests each selected provider with strict host checking.
It never accepts a new or changed host key. In 1Password mode it also requires
every selected provider's physical public pin to match an identity offered by
the 1Password agent, and the effective SSH configuration to use that socket,
that pin alone, and `IdentitiesOnly yes`. An unrelated agent identity is not
enough. A missing pin, configuration override, locked/unavailable agent or
failed provider test stops the audit. Diagnostics are suppressed; use the
[SSH troubleshooting guide](../manual/ssh-signing-and-recovery.md#troubleshoot-without-weakening-the-boundary)
locally, and independently confirm the provider identifies the intended account.
HTTPS mode skips SSH tests; CLI sessions are checked separately and do not
prove HTTPS access to every repository. Authentication is not commit-signature
verification or evidence of write access.

The storage inventory reads the physical `~/.ssh` tree, including hidden and
nested files. It looks for recognised private-key headers regardless of the
filename or `.pub` suffix, and treats non-public `id_*` files as candidates
even when malformed. Physical Unix sockets, such as SSH-agent endpoints, are
reported as SKIP: they are communication endpoints, not key files. The audit
does not connect to them or assess their trust, and still scans files beside
them. A socket cannot satisfy a required Keychain key-file check.
It does not follow symlinks, including links to sockets; unreadable files,
links, other special files (such as FIFOs) and incomplete scans block
verification rather than producing a clean result.
This is not a whole-disk or all-formats secret scan: keys outside
this tree and unrecognised formats without a conventional name may be missed.
Do not move or rename keys to make them disappear from the report.

| Result | Meaning and next action |
|---|---|
| PASS | The named check passed; for expected Keychain provider keys, encryption was detected |
| REVIEW | An encrypted legacy/additional key was found; decide whether its retention is justified |
| REVIEWED | You explicitly approved retaining that encrypted file during this audit; this is **not** a vault-only setup |
| SKIP | A physical Unix socket was excluded from key-file checks; this is not an authentication or endpoint-security pass |
| FAIL | A key is unprotected/unverifiable, a scan failed, or an authentication check failed; repair the named issue |

The encryption probe uses an empty passphrase non-interactively. It never asks
for or records the real passphrase, and does not measure its strength. Key
bytes are not printed or added to dotfiles. The audit does not change keys,
provider registrations, the SSH agent allow-list or global Git signing settings.

**Shared manual review, before approving retention:**

1. Identify the named file's owner and purpose. Inspect its matching **public**
   key's fingerprint, not the private contents.
2. Check other host configurations, repository/identity-specific signing
   settings and recovery procedures that may still depend on it. Successful
   GitHub authentication alone does not prove the old key is unused.
3. Verify the replacement route and a recovery plan. For an imported key with
   the same fingerprint, revoking the old provider registration also revokes
   the vault-backed copy; do not confuse deleting a redundant local copy with
   revoking an identity.
4. If retention is intentional, keep a private note of its purpose and review
   date. Otherwise arrange a separately approved migration or retirement with
   the key's owner. Never commit the private key, even to a private repository.

**Script-assisted continuation:** rerun `day-one-mac setup --phase 08` in a
terminal **without `--yes`**. For each encrypted legacy/additional file, type
`retain` only after the review above. Return leaves it at REVIEW. Approval is
per file, per audit; the file is checked again for changes after approval.
`--yes` and redirected/non-interactive input cannot approve retention. Pending
reviews return the manual-action status (10); failures take precedence. Expected
encrypted keys for the selected Keychain providers need no extra retention
prompt; additional keys do. Unprotected or unverifiable files cannot use this
exception. Nothing is deleted automatically.

**Manual route:** perform the same ownership, protection, authentication and
recovery review without Day One Mac commands and record the outcome yourself.
No runner report or approval marker is created.

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
| Encrypted legacy key remains REVIEW | Complete the per-file review above; rerun interactively without `--yes`. Do not delete or rename it just to pass |
| Provider SSH check fails after an agent check passes | Review the selected public pin, effective host configuration and provider trust; agent presence alone is insufficient |
| A required app passes but is absent from the Brewfile | Check `application-provenance.md`; external applications correctly remain outside Homebrew desired state |
| `brew bundle dump` says the Brewfile exists | Review and preserve it; the runner intentionally refuses overwrite |
| `chezmoi add ~/Brewfile` includes unexpected edits | Inspect `chezmoi diff` and apply only reviewed targets |
| Git push reports `Permission denied (publickey)` | Unlock 1Password, verify `ssh-add -l`, then repeat the provider SSH test from Phase 4 |
| The dotfiles repository is public | Change repository visibility before pushing machine configuration |
| Local-only mode reports no remote | This is expected; verify the chezmoi source is included in an encrypted backup |
| Secret scanning finds a credential | Remove it from source and Git history, then rotate the credential before pushing |

## Phase 8 completion checklist 🚦

- [ ] The project validator run by Phase 8 passes.
- [ ] The machine verification report contains no failed gate or pending review.
- [ ] Each retained encrypted legacy key is explicitly reviewed; the report does
      not describe a setup with retained disk keys as vault-only.
- [ ] Selected folders exist; if ghq was selected, its roots match the [reviewed layout](../manual/developer-folders.md).
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
