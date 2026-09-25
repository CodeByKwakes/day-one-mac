[← Advanced index](README.md) · **🤖 ⚙️ Advanced 15** · [Advanced 16 →](16-brewfile-apps-and-editor.md)

# Advanced 15 — Full dotfiles and bootstrap

**Time:** 45–90 minutes · **Required:** no · **Prerequisite:** required Phase 8

## Outcome

The minimal chezmoi source is expanded only for configuration you genuinely
want on another Mac. Machine data stays local, secrets remain excluded, hooks
are idempotent, and a complete inventory explains who owns each target.

Read [Chezmoi concepts and safety boundaries](../20-reference/CHEZMOI-CONCEPTS-AND-BOUNDARIES.md)
before expanding ownership. Use the
[command reference](../20-reference/CHEZMOI-COMMAND-REFERENCE.md) when choosing
between `edit`, `add`, `apply`, `merge`, and `forget`.

## Step 15.1 — Audit the minimal source first

```bash
day-one-mac --status
chezmoi doctor
chezmoi source-path
chezmoi managed | LC_ALL=C sort
chezmoi diff
```

Resolve an unexplained diff before adding more files. Record the current source
commit so rollback has an obvious boundary:

```bash
cd "$(chezmoi source-path)"
git status --short
git add --all
git diff --cached
git commit -m "chore: checkpoint minimal day-one-mac dotfiles"
```

Do not commit merely to silence `git status`. Review every staged file first.

## Step 15.2 — Use a three-class inventory

| Class | Examples | Treatment |
|---|---|---|
| Reproducible target | `.zshrc`, `.gitconfig`, Starship, editor preferences | Manage with chezmoi |
| Machine-local selection | track, stack, account labels, checkout root | Keep under `~/.config/chezmoi` or `~/.day-one-mac`; never commit |
| Credential or volatile state | private keys, auth JSON, Keychain, browser sessions, caches | Exclude from chezmoi and back up through the owning secure system |

Recommended advanced target inventory:

| Target | Source form | Add when |
|---|---|---|
| `~/.gitignore_global` | `dot_gitignore_global` | Already managed by Phase 5; extend only with truly global machine artefacts |
| `~/.npmrc` | `dot_npmrc.tmpl` | Only non-secret npm defaults are shared |
| `~/.config/pnpm/rc` | `dot_config/pnpm/rc` | pnpm defaults must reproduce |
| `~/.config/git/allowed_signers` | `dot_config/git/allowed_signers.tmpl` | SSH commit verification is used |
| `~/Library/Application Support/Code/User/settings.json` | macOS-specific source target | VS Code Sync is not the chosen owner |
| `~/.config/mcp/servers.md` | `dot_config/mcp/servers.md` | Optional MCP catalogue is in use |
| `~/.agents/skills/...` | `dot_agents/skills/...` | Advanced 22 is selected |
| `~/.local/bin/...` | `dot_local/bin/executable_*` | A reviewed personal helper must be portable |

Do not add all suggested targets at once. Add one category, inspect the diff,
and commit it before moving to the next.

## Step 15.3 — Keep machine data local

Open the machine-local config:

```bash
chezmoi edit-config
```

An expanded example is:

```toml
[edit]
command = "code"
args = ["--wait"]

[data]
track = "github"
stack = "both"
name = "Your Name"
email = "you@example.com"
secondary_email = ""
secondary_email_type = ""
onepassword_vault = "Developer"
```

Values differ by Mac. The file at `~/.config/chezmoi/chezmoi.toml` is input to
templates, not a source file to commit. Never store a token or password in this
table simply because it is untracked.

Before using a key in a template, fail clearly when it is absent:

```text
{{- if not (hasKey . "track") -}}
{{-   fail "machine data is missing track" -}}
{{- end -}}
```

## Step 15.4 — Review global Git ignores and add safe package defaults

Create or review the targets first:

```bash
test -f "$HOME/.gitignore_global"
mkdir -p "$HOME/.config/pnpm"
touch "$HOME/.config/pnpm/rc"
```

Useful global ignores are machine artefacts, not project build choices:

```gitignore
.DS_Store
.AppleDouble
.LSOverride
._*
.Trashes
*.swp
*.swo
*~
```

Do not globally ignore `.env`, lockfiles, build output, or editor folders merely
to hide an accidental commit. Repositories should declare those policies.

Safe npm/pnpm configuration can include registry and store behaviour, but not
credentials:

```ini
fund=false
audit=true
save-exact=true
```

Add and inspect:

```bash
chezmoi source-path "$HOME/.gitignore_global"
chezmoi add "$HOME/.config/pnpm/rc"
chezmoi diff
```

## Step 15.5 — Manage templates without embedding secrets

Render a proposed target before applying it:

```bash
chezmoi execute-template < "$(chezmoi source-path "$HOME/.gitconfig")"
chezmoi cat "$HOME/.gitconfig"
chezmoi diff
```

For a 1Password-backed value, prefer a runtime reference or a narrowly scoped
template read. First prove the referenced vault item exists with the 1Password
CLI. A missing item should fail the render instead of producing an empty
credential.

Never manage these targets:

```text
~/.ssh/id_*
~/.config/gh/hosts.yml
~/.azure/
~/.codex/auth.json
~/.claude/.credentials.json
~/.copilot/*auth*
~/Library/Group Containers/*1Password*
```

## Step 15.6 — Add bootstrap hooks carefully

chezmoi run scripts are useful for operations that are both reproducible and
safe to retry. Use source filenames such as:

```text
run_once_before_10-homebrew.sh.tmpl
run_once_after_20-toolchains.sh.tmpl
run_onchange_after_30-editor.sh.tmpl
```

Rules for every hook:

1. Start with `set -euo pipefail`.
2. Check current state before installation or modification.
3. Never prompt when chezmoi might run unattended.
4. Never delete user data or reset an application profile.
5. Never put a literal secret in the source.
6. Use `run_onchange_` only when a content change genuinely requires rerunning.

Preview hook execution before applying:

```bash
chezmoi state dump
chezmoi diff
chezmoi apply --dry-run --verbose
```

If a hook installs packages, the Brewfile remains desired state and the hook
should call `brew bundle check` before `brew bundle install`.

## Step 15.7 — Make personal helpers auditable

Store helpers below `~/.local/bin`, give them descriptive names, and include a
`--help` mode. Before adding one:

```bash
/bin/bash -n "$HOME/.local/bin/example-helper"
shellcheck "$HOME/.local/bin/example-helper" 2>/dev/null || true
"$HOME/.local/bin/example-helper" --help
```

Then:

```bash
chmod 700 "$HOME/.local/bin/example-helper"
chezmoi add "$HOME/.local/bin/example-helper"
chezmoi diff
```

A helper that removes data must default to preview, resolve exact targets, and
require a separate execute flag plus confirmation.

## Step 15.8 — Audit the complete source

Inventory filenames and symlinks:

```bash
cd "$(chezmoi source-path)"
find . -type f -print | LC_ALL=C sort
find . -type l -print -exec readlink {} \;
```

Search for credential shapes by filename first, then review matching files
locally without copying their contents into a shared log:

```bash
rg -l 'BEGIN .*PRIVATE KEY|github_pat_|ghp_|Bearer[[:space:]]|api[_-]?key' . || true
rg -n 'auth\.json|credentials|hosts\.yml|\.env($|\.)' . || true
```

Validate source-to-target behaviour:

```bash
chezmoi doctor
chezmoi verify
chezmoi diff
git status --short
```

## Rollback

Revert source changes through Git, preview the resulting target diff, then
apply only named targets. Do not restore a whole old home-directory snapshot.

```bash
cd "$(chezmoi source-path)"
git log --oneline -10
git revert <reviewed-commit>
chezmoi diff
chezmoi apply <reviewed-target>
```

## Advanced 15 completion checklist 🚦

- [ ] The minimal source had a clean, reviewed checkpoint.
- [ ] Every added target has one documented owner.
- [ ] Machine-local data is not in the source repository.
- [ ] Global ignores do not hide project-owned files.
- [ ] Hooks are non-interactive, idempotent, and previewed.
- [ ] Helpers default to safe behaviour and pass syntax checks.
- [ ] No credential file, private key, token, or literal secret is tracked.
- [ ] `chezmoi doctor`, `chezmoi verify`, and the reviewed diff pass.
- [ ] Private-Git mode has the final reviewed commit pushed; or local-only mode
      has a current encrypted backup of `~/.local/share/chezmoi`.

Record completion only after these checks:

```bash
day-one-mac advanced --complete 15
```

---

[← Advanced index](README.md) · [Continue to Advanced 16 →](16-brewfile-apps-and-editor.md)
