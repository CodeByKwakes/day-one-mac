# Set up language toolchains

Install only the language stack selected in your worksheet. Complete
[Homebrew](homebrew.md) and [Zsh startup configuration](shell/zsh.md) first.
Project version files take precedence over a convenient default runtime.

## Node and TypeScript

1. Install the selected managers.

   ```bash
   brew install fnm pnpm
   ```

   Expected result: `fnm --version` and `pnpm --version` succeed. Homebrew owns
   the global pnpm launcher.

2. Load fnm in the current Zsh session.

   ```zsh
   eval "$(fnm env --shell zsh)"
   ```

   Expected result: fnm can select an installed Node version. Keep its persistent
   `--use-on-cd` initialisation once in `.zshrc`, as the shell guide explains.

3. Install and select the current long-term support (LTS) Node release.

   ```bash
   fnm install --lts --use
   ```

   Expected result: `fnm current` identifies the selected release. For an existing
   project, use its `.node-version` or `.nvmrc` policy instead.

4. Set that installed release as the default for new sessions.

   ```bash
   fnm default "$(fnm current)"
   ```

   Expected result: a new shell without a project override can select that release.

5. Verify in a new login shell.

   ```bash
   zsh -lic 'fnm current && node --version && npm --version && pnpm --version'
   ```

   Expected result: all four checks succeed. `command -v pnpm` should resolve to
   the Homebrew-owned launcher; `node` should be selected by fnm.

Do not add Corepack, `npm install -g pnpm` or `pnpm setup` on top of this ownership
choice. Projects declare their package-manager expectation in `package.json`.
For an optional profile generator, use the
[shared Node.js minimum](../../shared/prerequisites.md#tool-prerequisites-by-task),
including on a Python-only Mac.

## Python

1. Install uv.

   ```bash
   brew install uv
   ```

   Expected result: `uv --version` reports the installed tool.

2. Install a uv-managed Python interpreter.

   ```bash
   uv python install
   ```

   Expected result: `uv python list` shows an installed managed interpreter.
   Follow a project's pinned Python requirement when one exists.

3. Verify the selected interpreter.

   ```bash
   "$(uv python find)" --version
   ```

   Expected result: a Python version from the uv-managed location. Do not replace
   macOS's system Python or install project packages into it.

## Verify a project

Open one authorised repository, inspect its runtime/version files and follow its
README to install dependencies and run tests. Record the commands and outcome.
A version check proves tool availability, not that every project builds.

## Troubleshooting and recovery

| Symptom | Action |
|---|---|
| Node works only in the old terminal | Check the single guarded fnm initialisation in `.zshrc` |
| Wrong Node after entering a project | Inspect its version file and `fnm current` |
| pnpm resolves to another owner | Inspect `type -a pnpm`; choose one owner before removing a conflicting launcher |
| Python points at macOS | Use `uv python find` and the project's environment |

Keep existing project lockfiles. Return to a previously installed runtime through
its manager if a project needs it; do not delete another project's environment.
Next: [selected applications](apps/README.md).
