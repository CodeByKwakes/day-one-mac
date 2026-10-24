# Zsh in VS Code and Warp

Choose your shell and file owner using the [manual shell task](README.md). Configure terminal-specific settings below only for applications you use; install VS Code later through its [manual task](../editors/vscode.md).

## 1. Use Zsh consistently in VS Code and Warp

Use a small shared Zsh configuration: one PATH helper, one Node version
manager, persistent history, and optional Starship. Keep terminal-specific
completion and editing separate. For this stack, a shell framework such as
Oh My Zsh is optional; adding it alongside the startup files in this guide
creates extra completion and prompt ownership to resolve.

These are personal home-file and **User Settings** changes, with no project
`.vscode` files required. If you selected chezmoi ownership, edit through
`chezmoi edit`, inspect the diff, and apply the selected file. Otherwise edit
your own home files directly. Merge the examples; do not replace your entire
configuration. See [shell ownership](README.md)
and the [reference files](../../../../templates/phase-05-shell-files/README.md).

### Choose one shell executable

Apple's `/bin/zsh` is a sensible default. If you deliberately selected Homebrew
Zsh for your setup, use `/opt/homebrew/bin/zsh` in both applications instead. Installing
Homebrew Zsh does not automatically change either application's selected shell.
This project supports native Apple silicon only; the Homebrew prefix is `/opt/homebrew`.

In Warp, find **Default shell for new sessions** in Settings and select the same
executable. In VS Code, use the profile below. A VS Code *terminal profile*
selects a shell; Default, Full Stack, Operations, and AI *editor profiles*
select settings and extensions. They are different features.

### Put initialization in the right files

| File | Recommended responsibility |
|---|---|
| `~/.zshenv` | Leave empty or minimal; runs for non-interactive shells too. No prompt, plugin loading, output, or automatic project `.env` loading |
| `~/.zprofile` | Login environment; source the shared PATH helper |
| `~/.config/zsh/path.zsh` | Idempotent Homebrew, personal executables, and selected package-manager PATH additions |
| `~/.zshrc` | Interactive shell: source PATH helper, history, Node manager, aliases, terminal-specific completion, prompt |
| `~/.config/starship.toml` | Optional shared prompt appearance |

Zsh reads `.zprofile` for login shells and `.zshrc` for interactive shells.
Keeping PATH available through both supports Warp sessions and non-login
integrated terminals. [Zsh startup files](https://zsh.sourceforge.io/Intro/intro_3.html).

Create the shared PATH helper and source lines below. Preserve
`typeset -U path PATH`, which removes duplicate PATH entries. Do not add another
`brew shellenv` or `fnm env` in several files. With the existing fnm selection,
keep its guarded `fnm env --use-on-cd --shell zsh` initialization once in
`.zshrc`; keep another selected Node manager instead if that is your setup.
Use the project's `.node-version`/`.nvmrc` policy to select Node, and confirm
`node --version` after entering each worktree. GUI-launched extensions and MCP
processes do not necessarily run `.zshrc`: a tool working in your terminal does
not prove its executable is available to the extension host.

## Create or merge the startup files

1. Back up existing `.zprofile`, `.zshrc` and `~/.config/zsh` with your chosen
   configuration owner. Keep a working terminal open.

   Expected result: you can restore the previous files without starting a new
   configured shell. Do not overwrite a known working file with these examples.

2. Create `~/.config/zsh` if missing, then save this as `path.zsh` there.

   Expected result: the helper adds native Homebrew and personal executable paths
   idempotently, so sourcing it twice does not duplicate PATH entries.

```zsh
# Shared PATH setup for login and non-login interactive zsh.
# Keep this file idempotent: both ~/.zprofile and ~/.zshrc source it.
typeset -U path PATH
if [[ -x /opt/homebrew/bin/brew ]] && {
  [[ ${HOMEBREW_PREFIX:-} != /opt/homebrew ]] ||
  [[ ":$PATH:" != *":/opt/homebrew/bin:"* ]] ||
  [[ ":$PATH:" != *":/opt/homebrew/sbin:"* ]]
}; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
```

3. Merge this source line into `~/.zprofile` once.

```zsh
[[ -r "$HOME/.config/zsh/path.zsh" ]] && source "$HOME/.config/zsh/path.zsh"
```

   Expected result: new login sessions load the shared PATH helper.

4. Merge the following into `~/.zshrc`, preserving unrelated configuration and
   removing duplicate initialisers rather than appending another copy.

```zsh
[[ -r "$HOME/.config/zsh/path.zsh" ]] && source "$HOME/.config/zsh/path.zsh"

HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=10000
setopt APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS HIST_VERIFY

if [[ ${TERM_PROGRAM:-} != WarpTerminal ]]; then
  for completion_dir in /opt/homebrew/share/zsh/site-functions /opt/homebrew/share/zsh-completions; do
    [[ -d "$completion_dir" ]] || continue
    (( ${fpath[(Ie)$completion_dir]} )) || fpath=("$completion_dir" $fpath)
  done
  unset completion_dir
  autoload -Uz compinit
  compinit
fi

if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --use-on-cd --shell zsh)"
fi

[[ -r "$HOME/.config/zsh/aliases.zsh" ]] && source "$HOME/.config/zsh/aliases.zsh"

if [[ ${TERM_PROGRAM:-} != WarpTerminal && -r /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# Search matching history in VS Code; preserve other terminals' keybindings.
if [[ ${TERM_PROGRAM:-} == vscode ]]; then
  bindkey '\e[A' history-beginning-search-backward
  bindkey '\e[B' history-beginning-search-forward
  bindkey '\eOA' history-beginning-search-backward
  bindkey '\eOB' history-beginning-search-forward
fi

# Syntax highlighting must be the final shell integration.
if [[ ${TERM_PROGRAM:-} != WarpTerminal && -r /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi
```

   Expected result: new interactive sessions get history, selected tools and one
   prompt. VS Code arrows search the typed prefix. Warp retains its native input
   behaviour. Syntax highlighting remains the final shell integration.

5. Check syntax before opening a new terminal.

```bash
/bin/zsh -n "$HOME/.zprofile" "$HOME/.zshrc" "$HOME/.config/zsh/path.zsh"
```

   Expected result: exit status zero with no syntax error. This does not execute
   the configuration; the new-session checks below test its behaviour.

If a new terminal fails, open `/bin/zsh -f` and restore the last reviewed change.
Do not close the known working terminal until the new session passes.

### Configure VS Code's terminal in every editor profile

Merge into **User Settings** in Default, Full Stack, Operations, and AI. Replace
the earlier `terminal.integrated.defaultProfile.osx` value with this named
profile. The font assumes the Nerd Font selected during Day One Mac setup.

```json
{
  "terminal.integrated.profiles.osx": {
    "Zsh — development": {
      "path": "/bin/zsh",
      "args": [],
      "icon": "terminal"
    },
    "Zsh — login diagnostics": {
      "path": "/bin/zsh",
      "args": ["-l"],
      "icon": "terminal"
    }
  },
  "terminal.integrated.defaultProfile.osx": "Zsh — development",
  "terminal.integrated.shellIntegration.enabled": true,
  "terminal.integrated.inheritEnv": true,
  "terminal.integrated.fontFamily": "JetBrainsMono Nerd Font, monospace",
  "terminal.integrated.fontSize": 13,
  "terminal.integrated.scrollback": 10000,
  "terminal.integrated.copyOnSelection": false,
  "terminal.integrated.enablePersistentSessions": true,
  "terminal.integrated.suggest.enabled": true,
  "terminal.integrated.suggest.upArrowNavigatesHistory": true,
  "terminal.external.osxExec": "Warp.app"
}
```

The normal profile uses `args: []` to avoid running macOS login PATH setup
again for every integrated terminal. This depends on sourcing the PATH helper
from `.zshrc`. The second profile is for comparing login behavior. VS Code
also resolves a login-shell environment when it starts; keep startup output
quiet and initialization repeatable.
[Terminal profiles and macOS PATH behavior](https://code.visualstudio.com/docs/terminal/profiles).

Automatic shell integration enables command boundaries, working-directory
tracking, and exit-status decorations. Let VS Code inject it; do not also
source it unconditionally in `.zshrc`. If detection fails, follow the official
manual fallback and restrict it to VS Code so it never runs in Warp.
[Shell integration](https://code.visualstudio.com/docs/terminal/shell-integration).

Persistent sessions help retain terminal state across editor reloads. Always
check `pwd` before an agent session; retention does not select the correct
worktree for you. `copyOnSelection: false` avoids replacing the clipboard
when selecting logs. Terminal suggestions are built into VS Code; no terminal
suggestion extension is required. If its dropdown competes with your shell's
grey suggestions, choose one: keep the dropdown and omit `zsh-autosuggestions`,
or set `terminal.integrated.suggest.enabled` to `false` in User Settings and
keep the shell plugin. The [VS Code baseline](../editors/vscode.md) enables the dropdown.

`terminal.external.osxExec` selects Warp for **Open New External Terminal**
(**Shift+Cmd+C**). Warp remains a separate application; it does not replace
the integrated terminal or render inside it. If launching from a folder does
not preserve that folder on your Warp version, open Warp and explicitly
`cd` there. [VS Code terminal basics](https://code.visualstudio.com/docs/terminal/basics).

### Search matching commands with Up and Down

Use prefix-based history search to cycle through earlier commands matching
what you have typed. For example, type `brew ` and press Up to find earlier
`brew` commands, skipping unrelated commands; Down moves toward newer matches.
The prefix is the text before the cursor. An empty prompt browses all history.
This searches commands already in your history; it does not generate new ones.

**Shared manual action for an existing setup:** merge this block into `.zshrc`
after prompt/plugins/keymap initialization and before syntax highlighting.
Use your selected configuration owner: edit the chezmoi source when managed,
or edit `.zshrc` directly when user-owned. Do not add the block twice.
The baseline above includes it; existing shell
files are preserved and need this manual merge.

```zsh
# Search matching history in VS Code; preserve other terminals' keybindings.
if [[ ${TERM_PROGRAM:-} == vscode ]]; then
  bindkey '\e[A' history-beginning-search-backward
  bindkey '\e[B' history-beginning-search-forward
  bindkey '\eOA' history-beginning-search-backward
  bindkey '\eOB' history-beginning-search-forward
fi
```

Both common arrow-key sequences are covered. No shell plugin or editor
extension is required. The VS Code guard leaves Warp's native input handling
alone. Keep your preferred Emacs/Vi keymap initialization before these bindings;
later keymap resets can replace them.
[Zsh history widgets](https://zsh.sourceforge.io/Doc/Release/Zsh-Line-Editor.html).

In VS Code **User Settings**, merge
`"terminal.integrated.suggest.upArrowNavigatesHistory": true` as shown above.
It sends Up to Zsh even when the suggestion dropdown is visible. The shared
profile configuration includes it for Default, Full Stack, AI and Operations.
If you instead want Up to navigate the visible completion dropdown, set it to
`false`; that is a different interaction from matching command history.
[VS Code terminal suggestions](https://code.visualstudio.com/docs/terminal/shell-integration#intellisense).

Close the old integrated terminal and create a new one. Try `brew ` followed
by Up/Down with the cursor after the space, then test an empty prompt. Only
matching commands you have previously run will be available. If it still
shows unrelated history, inspect the active bindings in that terminal:

```zsh
print -r -- "${TERM_PROGRAM:-unknown}"
bindkey '^[[A'
bindkey '^[[B'
```

Expect `vscode` and the backward/forward history-beginning-search widgets.

### Keep Warp's completion separate from Zsh plugins

Warp lists shell completion hooks, `compinit`, `zsh-autosuggestions`, some
custom keybindings, and other integrations as potential compatibility issues.
Use Warp's native completions and history suggestions there. For the shared
configuration, exclude completion and Zsh line-editor plugins from Warp using
its documented `TERM_PROGRAM=WarpTerminal` detection. This is a conservative
compatibility choice, not a claim that every plugin fails on every version.
[Warp known issues](https://docs.warp.dev/support-and-community/troubleshooting-and-support/known-issues).

Optional installation, if you want these features in VS Code and conventional
terminals:

```bash
brew install zsh-completions zsh-autosuggestions zsh-syntax-highlighting
```

The startup example above guards completion and ZLE plugins from Warp. Keep
that ordering when adding plugins. If using Starship in Warp, select its supported
custom-shell-prompt option and test a new tab; account features and labels can
vary by release. [Warp prompt settings](https://docs.warp.dev/terminal/appearance/prompt).

### Use terminal shortcuts deliberately

| Action | VS Code on macOS | Warp / shell guidance |
|---|---|---|
| Show integrated terminal | **Ctrl+`** | Warp is a separate app; use your macOS app-switch shortcut |
| New integrated terminal | **Ctrl+Shift+`** | Use Warp's new-tab action; inspect its Keyboard Shortcuts settings |
| Open external terminal | **Shift+Cmd+C** | Opens Warp when configured above |
| Terminal suggestions | **Ctrl+Space** | Use Warp's completion UI; don't bind Tab to `autosuggest-accept` |
| Accept history suggestion | **Right Arrow** with the shell plugin | Right Arrow at the end of input with Warp autosuggestions |
| Search shell history | **Ctrl+R** in a conventional Zsh terminal | Use Warp's history search; its input editor owns key handling |
| Cycle matching command history | Type a prefix, then **Up/Down** after the setup above | Use Warp's native history controls |
| Stop foreground command | **Ctrl+C** | **Ctrl+C** |
| End input / exit idle shell | **Ctrl+D** | Behavior depends on focused input and Warp keybindings |

Don't add a universal `bindkey '^J' ...`: Warp flags that binding as a possible
cause of needing Enter twice. Keep custom ZLE bindings in the same non-Warp
guard as plugins. Don't set `terminal.integrated.sendKeybindingsToShell: true`
just to resolve one key conflict; inspect VS Code's Keyboard Shortcuts editor
and change the individual binding instead.
[Warp autosuggestions](https://docs.warp.dev/terminal/command-completions/autosuggestions).

### Verify the same project in both applications

Open a **new** VS Code terminal and Warp tab, then enter the same repository or
worktree. Run these Zsh commands in each:

```zsh
printf 'zsh=%s terminal=%s login=%s interactive=%s\n' "$ZSH_VERSION" "${TERM_PROGRAM:-unknown}" "$options[login]" "$options[interactive]"
pwd
type -a node pnpm git
node --version
pnpm --version
print -l -- $path
```

`echo "$SHELL"` reports the configured login-shell preference; it does not
prove which executable the current terminal is running. Compare the versions,
PATH order, working directory, and selected shell path instead. Use terminal
tabs for Angular, NestJS, and one-shot checks; open an additional agent tab
from the specific worktree. Warp's AI account remains separate from Codex and
GitHub Copilot authentication.

If startup is slow, compare `time /bin/zsh -i -c exit` with
`time /bin/zsh -f -i -c exit` (use your selected executable). The latter skips
user RC initialization for diagnosis, not daily development. A temporarily
added `zmodload zsh/zprof` near the top of `.zshrc` and `zprof` at the bottom
can identify costly functions; remove both after measuring. Do not bypass
completion security checks with `compinit -u`; repair the reported ownership
or permissions instead.
[Completion security checks](https://zsh.sourceforge.io/Doc/Release/Completion-System.html#Use-of-compinit).
Start with the existing
[Warp troubleshooting guide](../terminals/warp.md#troubleshooting) for app-specific issues.
