[← Phase 5](05-dotfiles-and-shell.md) · **Phase 6** · [Phase 7 →](07-vscode-base.md)

# Phase 6 — Language toolchains and pnpm

**Time:** 15–35 minutes · **Required:** selected stack only

## Outcome

The selected runtime works in a new login shell. Node users have fnm, the
current Node LTS, npm, and a Homebrew-owned pnpm installation with a working
global-bin path. Python users have uv and a uv-managed interpreter. The laptop
guide does not freeze versions that will become stale.

## How to use this phase

- **Manual route:** complete the selected stack under
  [Manual 6](../20-reference/NOTION-SETUP-GUIDE.md#manual-6--install-the-selected-language-toolchains),
  then use the checks below.
- **Script-assisted route:** run `day-one-mac setup --phase 06`. It performs
  only the Node and/or Python route saved in Phase 1. The detailed commands
  below are for understanding and recovery. **LTS** means a longer-supported Node release; a **lockfile**
records exact project dependencies. See [GLOSSARY.md](../20-reference/GLOSSARY.md).

## Ownership model

| Concern | Owner |
|---|---|
| fnm, pnpm and uv executables | Homebrew |
| Node installations | fnm under the user account |
| Python installations | uv under the user account |
| Exact project runtime | Repository version file |
| Exact dependency graph | Repository lockfile |
| Exact pnpm expected by a Node project | `packageManager` in `package.json` |

One tool should own each global executable. The base setup does not run
`corepack enable` or install the Homebrew `corepack` formula because Corepack
conflicts with Homebrew's `pnpm` and `pnpx` launchers.

The commands are deliberately separate:

1. Homebrew installs only the `fnm` version manager and the native `pnpm`
   launcher.
2. `fnm install --lts --use` downloads the current Node LTS into
   `~/.local/share/fnm` and makes it the active/default Node.
3. Each fnm-managed Node includes its matching `npm` and `npx`; the setup does
   not install a second npm.
4. Current Homebrew pnpm is a native executable, so it remains available as a
   single Homebrew-owned launcher while fnm switches Node releases.
5. Repositories pin the runtime/package-manager expectation; the laptop guide
   intentionally does not preserve a dated global version.

## Node stack — Step 6.1: load fnm

The Installation Centre installed fnm. Load it in the current shell:

```bash
eval "$(fnm env --shell zsh)"
fnm --version
```

Phase 5 already added the automatic interactive-shell initialization to
`.zshrc`.

## Node stack — Step 6.2: install current LTS

```bash
fnm install --lts --use
fnm default "$(fnm current)"
node --version
npm --version
fnm current
fnm list
command -v node
command -v npm
npm prefix --global
```

`--use` activates the newly installed Node in the current shell; `fnm default`
additionally makes it the version that new terminals start with.

Sample output from the first few commands, with the Node LTS current at the
time of writing:

```text
v24.21.0
11.19.0
v24.21.0
* v24.21.0 default, current
/Users/your-name/Library/Caches/fnm_multishells/41725_1789294353/bin/node
```

`command -v node` and `command -v npm` should point inside fnm's active
multishell path — that is, a path containing `fnm_multishells`, as above. If
either instead prints something under `/opt/homebrew` or `/usr/local`, a second
Node installation is shadowing fnm; resolve that before continuing.

npm global packages are tied to that fnm-managed Node release,
so prefer Homebrew, `pnpm dlx`, `npx`, or project dev dependencies for CLIs
that must not disappear when the default Node changes.

The setup runner records the runtime directories before fnm writes them so the
precise rollback knows what was created.

Do not copy the displayed Node number into this guide. For a project that needs
that version, record it in the repository:

```bash
cd /path/to/project
node --version | sed 's/^v//' > .node-version
git add .node-version
```

With `--use-on-cd`, fnm switches when entering a directory containing a
supported version file.

## Node stack — Step 6.3: configure pnpm

The Homebrew formula provides the pnpm executable. The chezmoi-managed
Phase 5's shared `~/.config/zsh/path.zsh` provides this global-bin directory:

```text
~/Library/pnpm
```

`PNPM_HOME` is the environment variable naming that directory. `PATH` is the
ordered list of directories the shell searches when you type a command. Phase 5
places `PNPM_HOME` on `PATH`, allowing pnpm-installed user commands to run by
name without replacing the Homebrew-owned pnpm launcher.

Create and verify it:

```bash
mkdir -p "$HOME/Library/pnpm"
printf 'PNPM_HOME=%s\n' "${PNPM_HOME:-not-set}"
case ":$PATH:" in
  *":${PNPM_HOME:-__unset__}:"*) printf '✓ PNPM_HOME is on PATH\n' ;;
  *) printf '✗ PNPM_HOME is missing from PATH — reapply Phase 5 path.zsh, then run: exec /opt/homebrew/bin/zsh -l\n' ;;
esac
pnpm --version
command -v pnpm
brew --prefix pnpm
(cd "$HOME" && pnpm store path)
```

A successful run looks like this; your versions and paths will differ:

```text
PNPM_HOME=/Users/your-name/Library/pnpm
✓ PNPM_HOME is on PATH
12.4.2
/opt/homebrew/bin/pnpm
/opt/homebrew/opt/pnpm
/Users/your-name/Library/pnpm/store/v10
```

The last line is the package store; its `v` suffix changes between pnpm
releases, so any version there is fine. What matters is that `command -v pnpm`
resolves under `/opt/homebrew`.

This block only reports; it never closes your terminal. If the PATH line shows
`✗`, fix it and run the block again.

`command -v pnpm` should resolve through Homebrew's bin directory, not a
Corepack or npm-global shim. `PNPM_HOME` is reserved for pnpm's user-level
global command links; the content-addressed package store returned by
`pnpm store path` is a separate location.

Do not run `pnpm setup` after Phase 5; it would edit a shell file that chezmoi
already owns. Do not install pnpm again with `npm install --global pnpm`.

For each Node repository:

1. Commit exactly one dependency lockfile.
2. Commit `.node-version` or `.nvmrc`.
3. Set `packageManager` to the exact pnpm version tested by that repository.

Example command using the installed version without hardcoding this guide:

```bash
cd /path/to/project
PNPM_VERSION="$(pnpm --version)"
npm pkg set "packageManager=pnpm@$PNPM_VERSION"
pnpm install
git add package.json pnpm-lock.yaml .node-version
```

Do not run that command in an npm repository unless you intentionally want to
migrate its lockfile and scripts.

## Python stack — Step 6.4: install an interpreter with uv

The Installation Centre installed the uv executable. Install uv's current default Python:

```bash
uv --version
uv python install
uv python list
"$(uv python find)" --version
```

For a new Python project:

```bash
mkdir -p ~/Developer/_sandbox/python-check
cd ~/Developer/_sandbox/python-check
uv init
uv add --dev ruff
uv run python --version
uv run ruff check .
```

Commit `pyproject.toml`, `uv.lock`, and `.python-version` when present. Virtual
environments and caches remain local.

## Step 6.5 — Run or resume the phase

```bash
day-one-mac setup --phase 06
```

The runner checks only the selected stack. A Python-only machine is not failed
because Node is absent, and a Node-only machine does not install Python.

## Step 6.6 — Verify a new shell

Close and reopen Terminal, then run the appropriate block:

```bash
# node or both
zsh -lic 'fnm current && node --version && npm --version && pnpm --version'
zsh -lc 'test -n "$PNPM_HOME" && test -d "$PNPM_HOME"'

# python or both
uv --version
"$(uv python find)" --version
```

## Troubleshooting

| Symptom | Resolution |
|---|---|
| `fnm: command not found` | Open a new login shell and confirm both startup files load `~/.config/zsh/path.zsh` |
| `node: command not found` after fnm installation | Confirm the fnm block is in `.zshrc`, then run `exec /opt/homebrew/bin/zsh -l` |
| pnpm says its global bin is not on PATH | Reapply the Phase 5 `~/.config/zsh/path.zsh`, verify `$PNPM_HOME`, and reopen the terminal |
| Two different pnpm executables appear | Inspect `command -v -a pnpm`; remove Corepack/npm shims and retain Homebrew's executable |
| A project requires another Node release | Put the required version in `.node-version`, then run `fnm install` in that project |
| uv selects an unexpected Python | Inspect `.python-version` and `uv python list`, then pin the project intentionally |

## Phase 6 completion checklist 🚦

- [ ] Every selected executable reports a version.
- [ ] Node selections have a current LTS default in fnm.
- [ ] Node selections have npm and pnpm working in a new terminal.
- [ ] `PNPM_HOME` exists and is on PATH for Node selections.
- [ ] Python selections have a uv-managed interpreter.
- [ ] No unselected language is required to pass.
- [ ] Project versions will be committed in repositories rather than this guide.

References: [fnm](https://github.com/Schniz/fnm),
[pnpm installation](https://pnpm.io/installation),
[Homebrew pnpm formula](https://formulae.brew.sh/formula/pnpm), and
[uv documentation](https://docs.astral.sh/uv/).

---

[← Phase 5](05-dotfiles-and-shell.md) · [Continue to Phase 7 →](07-vscode-base.md)
