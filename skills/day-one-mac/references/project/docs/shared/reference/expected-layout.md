# Expected filesystem layout

These are default locations, not prerequisites. Keep an existing project layout
unless you deliberately choose to change it. See [folder choices](../../setup/manual/development/folders.md).

| Location | Owner and purpose |
|---|---|
| `~/Developer/` | Your repositories, resources and experiments |
| `~/Brewfile` | Your reviewed software list, if you use Homebrew Bundle |
| `~/.zprofile`, `~/.zshrc`, `~/.config/zsh/` | Your shell configuration or your selected dotfile manager |
| `~/Library/Application Support/Code/User/` | VS Code User Settings and named profiles |
| `~/.local/bin/day-one-mac` | Optional utility launcher |
| `~/.local/share/day-one-mac/releases/<version>/` | Versioned utility bundle |
| `~/.local/share/day-one-mac/current` | Active runtime symlink |
| `~/.day-one-mac/` | Private utility state, ownership records and recovery evidence |
| A new directory you choose for AI setup | Exported skills, roles, recipes and private session notes |

A normal setup needs no permanent checkout of this repository. Do not store
active repositories in a cloud-synchronised folder. Use one owner for each
configuration file: edit it directly or through your chosen dotfile manager.

## Inspect your paths

1. Inspect the shell's command resolution.

   ```bash
   command -v git node code
   ```

   Expected result: paths for installed commands. Missing commands need their
   own installation or PATH repair; multiple copies can have different owners.

2. Inspect an optional installed utility bundle.

   ```bash
   day-one-mac root
   day-one-mac runtime-status
   ```

   Expected result: the active version directory and integrity status.

3. Inspect the selected assistant export.

   ```bash
   day-one-mac assistant --check "$HOME/Developer/setup-session"
   ```

   Expected result: a verified export, if that is the directory you created.
   This does not verify the machine's setup or the AI provider connection.

## Recovery

Keep ownership records and backups until you have tested restoration. Runtime
rollback changes the tool version, not the applications or settings. Follow
[runtime lifecycle](../tools/runtime.md) and [recorded recovery](../tools/rollback.md)
for their separate scopes.
