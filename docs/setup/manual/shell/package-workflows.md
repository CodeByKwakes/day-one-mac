# Maintain shell and package-manager workflows

Use this task with a working [Zsh setup](zsh.md). The package-manager sections
also require the selected [Node toolchain](../languages.md) and a disposable
project for checks. Back up shell files through their current owner.
Run ghq, chezmoi and plugin-specific commands only when those tools are selected.

If using the private report paths below, first create the directory with `mkdir -p "$HOME/.local/state/development-setup"` and restrict it with `chmod 700 "$HOME/.local/state/development-setup"`. Expected: reports remain local and outside the repository.

## 1. Measure before adding plugins

```bash
for run in 1 2 3 4 5; do /usr/bin/time zsh -lic exit; done
zsh -lic 'command -v brew git ghq chezmoi starship'
```

Record a rough median. Shell plugins are optional only when their daily value
exceeds their startup and maintenance cost.

If `compinit` reports insecure directories:

```bash
zsh -f -c 'autoload -Uz compaudit && compaudit'
```

Fix only the paths listed and only when you own them. Never recursively change
permissions across Homebrew, `/usr/local`, or the complete home directory.

## 2. Install selected enhancements

Install each selected formula with `brew install <formula>` after checking that no existing tool already covers that workflow. Expected: the selected command appears on PATH.

The most useful groups from the wider setup are:

```text
Navigation:  eza, zoxide, fzf
Reading:     bat, tldr, jq, yq
Git:         delta, lazygit, gh
Processes:   btop or htop, dust, duf
Containers:  lazydocker
Shell:       zsh-autosuggestions, zsh-syntax-highlighting
```

Install only one overlapping tool unless a real workflow distinguishes them.
Record selected formulae in your reviewed Brewfile if you maintain one.

## 3. Review or extend safe navigation and maintenance aliases

Keep aliases in a dedicated file owned by your selected configuration method. Review
or extend that file instead of mixing aliases into `.zshrc`:

For chezmoi-owned files, use `chezmoi edit "$HOME/.config/zsh/aliases.zsh"`. Otherwise edit that file directly. Source it once from `.zshrc`, then verify with `zsh -n` before opening a new shell.

The examples below group Git, chezmoi and Homebrew commands. Add `cdev` or the Docker group only if those workflows are useful:

```zsh
# Repositories and Git
alias cdev='cd "$HOME/Developer"'
alias gs='git status --short --branch'
alias gd='git diff'
alias gds='git diff --staged'
alias gl='git log --oneline --graph --decorate -20'
alias gremotes='git remote --verbose'

# Homebrew — inspection and preview first
alias brewcheck='brew bundle check --file="$HOME/Brewfile" --no-upgrade'
alias brewout='brew outdated --greedy'
alias brewcleanpreview='brew cleanup --dry-run'
alias brewautopreview='brew autoremove --dry-run'

# chezmoi
alias cm='chezmoi'
alias cmstatus='chezmoi status'
alias cmdiff='chezmoi diff'
alias cmdifftext='chezmoi --use-builtin-diff diff --no-pager'
alias cmmerge='chezmoi merge'
alias cmverify='chezmoi verify'
alias cmdoctor='chezmoi doctor'

# Containers — non-destructive lifecycle
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dcps='docker compose ps'
alias dclogs='docker compose logs --tail 100'
```

Avoid aliases that combine upgrade, cleanup, and health checks; failure midway
makes the final state unclear. Also exclude one-key commands for force pushes,
soft resets, WIP commits that bypass hooks, Docker volume pruning, database
volume deletion, AI full-auto modes, or package publication.

## 4. Detect the repository package manager

The base intentionally installs:

- Node LTS through fnm.
- npm supplied by that Node release.
- pnpm as a Homebrew-owned executable.
- No global Yarn or Bun unless a project explicitly requires one later.

Add this zsh function to choose between npm and pnpm without changing either:

```zsh
function pm_for_dir() {
  if [[ -f pnpm-lock.yaml ]]; then
    print pnpm
  elif [[ -f package-lock.json || -f npm-shrinkwrap.json ]]; then
    print npm
  elif [[ -f package.json ]]; then
    local declared
    declared="$(node -p 'try { require("./package.json").packageManager || "" } catch (_) { "" }' 2>/dev/null)"
    case "$declared" in
      pnpm@*) print pnpm ;;
      npm@*|'') print npm ;;
      *) print -u2 "unsupported packageManager: $declared"; return 1 ;;
    esac
  else
    print -u2 'no package.json or supported lockfile in this directory'
    return 1
  fi
}

function pm() {
  local manager
  manager="$(pm_for_dir)" || return
  command "$manager" "$@"
}
```

Verify both directions in disposable fixtures:

```bash
mkdir -p /tmp/day-one-mac-pm/npm /tmp/day-one-mac-pm/pnpm
printf '{"private":true}\n' > /tmp/day-one-mac-pm/npm/package.json
touch /tmp/day-one-mac-pm/npm/package-lock.json
printf '{"private":true}\n' > /tmp/day-one-mac-pm/pnpm/package.json
touch /tmp/day-one-mac-pm/pnpm/pnpm-lock.yaml
zsh -lic 'cd /tmp/day-one-mac-pm/npm && pm_for_dir'
zsh -lic 'cd /tmp/day-one-mac-pm/pnpm && pm_for_dir'
```

Expected output is `npm` then `pnpm`.

## 5. Enforce reproducible installs

Add a separate frozen-install helper rather than hiding the policy inside `pm`:

```zsh
function pm_frozen() {
  case "$(pm_for_dir)" in
    pnpm) command pnpm install --frozen-lockfile ;;
    npm)  command npm ci ;;
    *) return 1 ;;
  esac
}
```

Use normal `pm install` only while intentionally changing dependencies. CI,
rebuilds, and fresh worktrees should use `pm_frozen`.

Repository declarations remain authoritative:

```json
{
  "engines": { "node": ">=22" },
  "packageManager": "pnpm@<project-version>"
}
```

Do not copy a global version from this playbook. Pin the exact version selected
and tested by the project, commit the corresponding lockfile, and let fnm read
`.node-version` or `.nvmrc` where present.

## 6. Prevent silent package downloads

Prefer installed project commands:

```bash
pnpm exec eslint .
npm exec --offline -- eslint .
```

Use `pnpm dlx` or downloading `npx` only when you have reviewed the package,
version, source, and intended temporary execution. For scaffolding, pin a
version instead of relying on an unreviewed `latest` tag.

## 7. Audit package-manager drift across ghq repositories

From the ghq root:

```bash
while IFS= read -r repository; do
  directory="$(ghq root)/$repository"
  [[ -f "$directory/package.json" ]] || continue
  locks=""
  [[ -f "$directory/pnpm-lock.yaml" ]] && locks="${locks} pnpm"
  [[ -f "$directory/package-lock.json" ]] && locks="${locks} npm"
  [[ -f "$directory/yarn.lock" ]] && locks="${locks} yarn"
  [[ -f "$directory/bun.lock" || -f "$directory/bun.lockb" ]] && locks="${locks} bun"
  printf '%-60s %s\n' "$repository" "${locks:- NO-LOCKFILE}"
done < <(ghq list)
```

Flag repositories with multiple lockfile families, a declared manager that does
not match the lockfile, or no lockfile for an application. Do not delete a
lockfile automatically; the repository may be in a deliberate migration.

## 8. Audit repository risk before maintenance

```bash
while IFS= read -r repository; do
  directory="$(ghq root)/$repository"
  [[ -d "$directory/.git" ]] || continue
  dirty="$(git -C "$directory" status --porcelain)"
  remote="$(git -C "$directory" remote get-url origin 2>/dev/null || true)"
  [[ -n "$dirty" ]] && state=DIRTY || state=CLEAN
  [[ -n "$remote" ]] || remote=NO-REMOTE
  printf '%s\t%s\t%s\n' "$state" "$remote" "$repository"
done < <(ghq list) | tee "$HOME/.local/state/development-setup/repository-audit.tsv"
```

Review every `DIRTY` and `NO-REMOTE` line before OS upgrades, broad cleanup, or
migration. A local commit without a remote is not a backup.

## 9. Apply and remeasure

If chezmoi owns the aliases, review and apply that target:

```bash
chezmoi diff
chezmoi apply "$HOME/.config/zsh/aliases.zsh"
```

If you own the file directly, save the reviewed edit. Check its syntax:

```bash
zsh -n "$HOME/.config/zsh/aliases.zsh"
```

Expected result: no syntax error. Open a new terminal with the selected Zsh,
then repeat the startup measurement:

```bash
for run in 1 2 3 4 5; do /usr/bin/time zsh -lic exit; done
```

Remove or lazy-load any optional plugin that materially slows every shell.

## Rollback

Restore `aliases.zsh` through its selected owner. For a versioned chezmoi
source, revert the reviewed source commit and apply that single target.
Uninstall an optional formula only after `brew uses --installed <formula>` shows its reverse
dependencies and the Brewfile declaration has been reviewed.

## Verification and next steps

Open a new terminal and confirm that the selected commands are available.
In each test project, check that `pm_for_dir` matches its package-manager
declaration and lockfile. Investigate conflicting declarations before installing
dependencies. Unselected tools are not failed checks. Record startup timing and
return to any calling assisted module after reviewing the results.

## Troubleshooting

| Symptom | Next action |
|---|---|
| `pm_for_dir` chooses an unexpected manager | Inspect `packageManager` and the lockfiles; resolve conflicting repository declarations before installing |
| A command is missing in a new terminal | Check the selected tool's installation and the PATH helper in the Zsh guide |
| A plugin increases startup time | Compare the timings from Steps 1 and 9, then remove or defer the selected plugin |
| An alias behaves incorrectly | Restore that alias file through its owner, check syntax and open a new terminal |
