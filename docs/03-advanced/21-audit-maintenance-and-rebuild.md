[← Advanced 20](20-restore-and-migrate.md) · **🤖 ⚙️ Advanced 21** · [Advanced 22 →](22-ai-skills-and-mcp-operations.md)

# Advanced 21 — Audit, maintenance, and rebuild

**Time:** 30–90 minutes initially; 20–30 minutes monthly · **Required:** no

## Outcome

The expanded environment has a repeatable audit, updates happen in small
reviewable layers, dotfiles and Brewfile changes are committed privately, and
a clean-Mac rebuild is rehearsed without relying on remembered manual steps.

## Step 21.1 — Revalidate the project and required base

```bash
day-one-mac validate
day-one-mac --status
day-one-mac advanced --status
```

The required eight phases must remain current. An advanced marker becoming
`review` means its guide changed after completion; read the updated module and
repeat only its affected checks.

## Step 21.2 — Generate the extended audit

This is an **optional after-setup health report**. Use it after Phase 8 when you
have adopted advanced Modules 15–22, and repeat it during monthly maintenance.
It is not the Stage 0 safety report used before erasing or cleaning an existing
Mac.

Run the bundled read-only report:

```bash
day-one-mac advanced-audit
```

It writes `~/.day-one-mac/advanced-audit.md` and checks the base command
surface, Brewfile drift, chezmoi state, ghq repositories, selected track and
stack, optional containers, and discovered AI clients without printing tokens.

Open the report locally:

```bash
sed -n '1,260p' "$HOME/.day-one-mac/advanced-audit.md"
```

An optional component is reported as absent, not failed, unless its advanced
module is recorded complete.

## Step 21.3 — Review Homebrew updates in layers

```bash
brew update
brew outdated --greedy
brew bundle check --file="$HOME/Brewfile" --no-upgrade
```

Before upgrading:

1. Review major runtime, database, container, and editor changes.
2. Commit or preserve dirty repositories.
3. Confirm an application is not in the middle of a critical task.
4. Upgrade a risky formula/cask individually before broad upgrades.

After approved upgrades:

```bash
brew cleanup --dry-run
brew autoremove --dry-run
brew doctor
```

Run non-preview cleanup only after reading its candidates. `brew doctor`
warnings are context-dependent; do not recursively change ownership or delete
paths simply to produce an empty report.

## Step 21.4 — Maintain Node, npm, and pnpm ownership

The base ownership model is:

```text
fnm       installed by Homebrew, owns Node versions
Node      installed under fnm
npm       supplied by the active Node release
pnpm      installed/upgraded by Homebrew
projects  own exact runtime/manager constraints and lockfiles
```

Review current versions:

```bash
fnm current
fnm list
node --version
npm --version
pnpm --version
```

Install a new LTS through fnm, test active projects, then change the default:

```bash
fnm install --lts --use
fnm default "$(fnm current)"
```

Do not globally force the newest npm or pnpm merely because a registry offers
it. Repositories with a `packageManager` field and lockfile must be tested
against their declared version policy.

Audit projects using the commands in Advanced 17. Resolve multiple lockfiles
repository by repository.

## Step 21.5 — Maintain Python through uv

```bash
uv self version
uv python list
```

Homebrew owns the `uv` executable when installed by the base. Projects own
their interpreter constraint and lockfile:

```bash
cd <python-project>
uv sync --locked
uv run python --version
uv run pytest
```

Do not install a second uv through pip or its standalone installer on the same
Mac without intentionally changing ownership.

## Step 21.6 — Review chezmoi and Brewfile drift

```bash
chezmoi doctor
chezmoi status
chezmoi --use-builtin-diff diff --no-pager
chezmoi verify
brew bundle check --file="$HOME/Brewfile" --no-upgrade
```

When changing a target, edit source first:

```bash
chezmoi edit <target>
chezmoi diff
chezmoi apply <target>
```

Commit only reviewed, secret-free source changes:

```bash
cd "$(chezmoi source-path)"
git status --short
git diff
git add <reviewed-files>
git diff --cached
git commit -m "chore: maintain development environment"
git push
```

## Step 21.7 — Review every repository before system work

Generate the Advanced 17 repository audit and investigate:

- `DIRTY` repositories;
- `NO-REMOTE` repositories;
- local branches ahead of their upstream;
- remote URLs that no longer match the intended provider/account;
- worktrees with uncommitted changes.

Useful read-only commands:

```bash
git -C <repository> status --short --branch
git -C <repository> remote --verbose
git -C <repository> branch --verbose --verbose
git -C <repository> worktree list
```

Never bulk-reset or delete branches as a maintenance step.

## Step 21.8 — Verify optional services

### Containers and databases

```bash
docker version
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
docker volume ls
```

Run a harmless ping/query for each selected service. Create a logical backup
before image upgrades or schema changes. Do not run global prune commands from
a maintenance alias.

### AI and MCP

For installed clients, verify version and account independently, then list MCP
servers with the client's supported command. Confirm the intended account and
workspace before a billable or state-changing tool call. Keep auto-approval
disabled.

### VS Code and GUI applications

Check Settings Sync account, active profile, declared extensions, login items,
and privacy permissions. Do not treat cloud sync as a complete settings backup.

## Step 21.9 — Use a maintenance cadence

| Frequency | Review |
|---|---|
| Weekly | repository status, security updates, active container health |
| Monthly | full advanced audit, Homebrew drift/outdated list, chezmoi diff, application inventory |
| Quarterly | unused applications/extensions, privacy permissions, login items, SSH keys, recovery contacts |
| Before major macOS upgrade | verified independent backup, clean/remote-backed repos, database dumps, fresh audit report |
| After major upgrade | Xcode tools, Homebrew doctor, shell startup, container runtime, editor, provider authentication |

Automate reminders if useful, but keep upgrades interactive. A scheduled task
should report available changes, not install or delete them unattended.

## Step 21.10 — Rehearse the rebuild

Write down the inputs a different clean Mac needs:

```text
1. The public Day One Mac release installer, or an offline release archive and checksum
2. Selected track and stack
3. Git name/email and provider accounts
4. 1Password account and Emergency Kit/recovery process
5. Private dotfiles repository URL
6. Project repository URLs
7. Optional module choices
8. Separately verified document/database backup when applicable
```

Rehearsal sequence:

```bash
day-one-mac setup --dry-run --track <1|2|3> --stack <node|python|both>
day-one-mac setup --track <1|2|3> --stack <node|python|both> \
  --dotfiles-repo <private-url>
day-one-mac validate
day-one-mac advanced-audit
```

Then install only the selected optional/advanced modules. The goal is not a
literal ten-minute stopwatch; it is a short, deterministic operator sequence
with no undisclosed source files or remembered commands.

## Step 21.11 — Test rollback without executing it

```bash
day-one-mac rollback
day-one-mac clean
```

Review the preview output and recovery archive plan. Do not run `--execute` as
a routine test. A useful rollback rehearsal proves exact ownership and backup
destinations without deleting the working environment.

## Advanced 21 completion checklist 🚦

- [ ] Required and advanced progress reports contain no unexplained review state.
- [ ] The extended audit has no unexplained failure.
- [ ] Homebrew updates are reviewed before upgrade or cleanup.
- [ ] fnm/Node/npm/pnpm and uv have one owner each.
- [ ] chezmoi and Brewfile drift are understood and privately committed.
- [ ] Dirty, ahead, and `NO-REMOTE` repositories are resolved or documented.
- [ ] Optional services pass harmless smoke tests.
- [ ] A maintenance cadence and pre-upgrade backup gate are recorded.
- [ ] The rebuild inputs and sequence are complete.
- [ ] Both cleanup modes have been previewed and understood.

```bash
day-one-mac advanced --complete 21
```

---

[← Advanced 20](20-restore-and-migrate.md) · [Continue to Advanced 22 →](22-ai-skills-and-mcp-operations.md)
