# Day One Mac Warp command catalogue

The bundle contains 63 workflows in seven folders. Setup and recovery actions
open guides or preview bounded operations. Review the command shown by Warp
before running it. Imports do not grant AI execution permission.

Use `day-one-mac root` to locate the installed bundle. GitHub and Azure commands
need the corresponding CLI and account; omit workflows for providers you do not
use. No workflow includes destructive `--execute` approval. Package installs and
projectless task creation are labelled by their action and require your review.

Old imported copies are not updated automatically. Remove obsolete wizard,
reset, finalisation and broad cleanup workflows from Warp before reimporting.
The retained filenames preserve export compatibility, not the old command behaviour.

| Workflow | Command |
|---|---|
| Day One · Runtime status | `day-one-mac runtime-status` |
| Setup · Validate Day One Mac project | `day-one-mac validate` |
| Day One \u00b7 Migration help 03-guided-preview | `day-one-mac docs open docs/shared/migration/from-scripted-setup.md` |
| Day One · AI assistance plan | `day-one-mac assistant --plan` |
| Day One · Read manual setup | `day-one-mac docs manual` |
| Setup · Write application inventory | `day-one-mac inventory` |
| Setup · List optional CLI tools | `day-one-mac cli-tools --list` |
| Setup · Select optional CLI tools | `day-one-mac cli-tools` |
| Setup · Show project root | `day-one-mac root` |
| Advanced · Show module status | `day-one-mac advanced --status` |
| Day One · List reviewed tools | `day-one-mac tool --list` |
| Advanced · Read one module | `day-one-mac advanced --module "{{module}}` |
| Advanced · Write environment report | `day-one-mac advanced-audit` |
| Advanced · Check environment report | `day-one-mac advanced-audit --check` |
| Day One · Inspect tool status | `day-one-mac modules` |
| Day One · Check runtime integrity | `day-one-mac verify` |
| Day One · Open setup documentation | `day-one-mac docs open` |
| Day One · Read migration guidance | `day-one-mac docs open docs/shared/migration/from-scripted-setup.md` |
| Day One · Read manual lifecycle | `day-one-mac docs open docs/setup/manual/lifecycle.md` |
| Cleanup · Preview recorded rollback | `day-one-mac rollback` |
| Cleanup · Preview complete recorded rollback | `day-one-mac rollback --all-recorded` |
| Day One \u00b7 Migration help 05-reset-progress-preview | `day-one-mac docs open docs/shared/migration/from-scripted-setup.md` |
| Day One · Inspect application ownership | `day-one-mac applications` |
| Day One · Preview runtime removal | `day-one-mac uninstall-runtime` |
| Repositories · Show ghq root | `ghq root` |
| Repositories · List ghq repositories | `ghq list` |
| Repositories · Clone with ghq | `ghq get "{{repository}}` |
| Git · Status | `git status --short --branch` |
| Git · Show remotes | `git remote --verbose` |
| GitHub · Check authentication | `gh auth status` |
| Azure · Show active account | `az account show --output table` |
| Azure · List repositories | `az repos list --output table` |
| Dotfiles · Status | `chezmoi status` |
| Dotfiles · Preview changes in VS Code | `chezmoi diff` |
| Dotfiles · Run doctor | `chezmoi doctor` |
| Dotfiles · List managed targets | `chezmoi managed` |
| Dotfiles · Edit one target | `chezmoi edit "{{target}}` |
| Dotfiles · Apply one reviewed target | `chezmoi apply "{{target}}` |
| Dotfiles · Verify targets | `chezmoi verify` |
| Toolchains · Show installed versions | `for tool in fnm node npm pnpm uv; do if command -v "$tool" >/dev/null 2>&1; then printf "%-8s " "$tool"; "$tool" --version; else printf "%-8s not installed\n" "$tool"; fi; done` |
| fnm · Show current Node | `fnm current` |
| fnm · Install and use current LTS | `fnm install --lts --use` |
| npm · List project scripts | `npm run` |
| npm · Audit dependencies | `npm audit` |
| pnpm · Install frozen dependencies | `pnpm install --frozen-lockfile` |
| pnpm · Audit dependencies | `pnpm audit` |
| pnpm · Check store status | `pnpm store status` |
| Python · List uv interpreters | `uv python list` |
| Python · Sync locked environment | `uv sync --locked` |
| Homebrew · Check Brewfile | `brew bundle check --file="$HOME/Brewfile" --no-upgrade` |
| Homebrew · List outdated packages | `brew outdated --greedy` |
| Homebrew · Refresh package metadata | `brew update` |
| Homebrew · Run doctor | `brew doctor` |
| Homebrew · Preview cleanup | `brew cleanup --dry-run` |
| Homebrew · Preview autoremove | `brew autoremove --dry-run` |
| AI workspace · Create an untitled task | `TASK_DIR="$(day-one-mac workspace create-task --title Untitled --kind other --client undecided --sensitivity private --quiet)" && cd "$TASK_DIR" && printf "Created and opened:\n%s\n" "$TASK_DIR` |
| AI workspace · Create a named task | `TASK_DIR="$(day-one-mac workspace create-task --title "{{task_name}}" --kind "{{task_kind}}" --client undecided --sensitivity private --quiet)" && cd "$TASK_DIR" && printf "Created and opened:\n%s\n" "$TASK_DIR` |
| AI workspace · List projectless tasks | `day-one-mac workspace list` |
| AI workspace · Open this task in VS Code | `day-one-mac workspace open-vscode "$PWD` |
| AI workspace · Start a new Codex chat here | `day-one-mac workspace start-codex "$PWD` |
| AI workspace · Start a new Claude Code chat here | `day-one-mac workspace start-claude "$PWD` |
| AI workspace · Start a new Copilot CLI chat here | `day-one-mac workspace status "$PWD" >/dev/null && copilot -C "$PWD` |
| AI workspace · Open a new Copilot app session here | `day-one-mac workspace status "$PWD" >/dev/null && copilot app` |
