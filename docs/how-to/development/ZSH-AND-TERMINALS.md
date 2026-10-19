# Zsh in VS Code and Warp

This focused reference was extracted from the advanced VS Code guide.
Follow the [base editor setup](../apps/VSCODE.md) and [profile guide](../apps/VSCODE-PROFILES.md) first.
[Advanced development reference](VSCODE-TYPESCRIPT.md).

## 12. Use Zsh consistently in VS Code and Warp

Use a small shared Zsh configuration: one PATH helper, one Node version
manager, persistent history, and optional Starship. Keep terminal-specific
completion and editing separate. For this stack, a shell framework such as
Oh My Zsh is optional; adding it alongside the existing Phase 5 initialization
creates extra completion and prompt ownership to resolve.

These are personal home-file and **User Settings** changes, with no project
`.vscode` files required. If Phase 5 selected chezmoi ownership, edit through
`chezmoi edit`, inspect the diff, and apply the selected file. Otherwise edit
your own home files directly. Merge the examples; do not replace your entire
configuration. See [shell ownership](../../setup/assisted/05-dotfiles-and-shell.md)
and the [reference files](../../../templates/phase-05-shell-files/README.md).

### Choose one shell executable

Apple's `/bin/zsh` is a sensible default. If you deliberately selected Homebrew
Zsh in Phase 5, use `/opt/homebrew/bin/zsh` in both applications instead. Installing
Homebrew Zsh does not automatically change either application's selected shell.
On an Intel Mac, confirm the actual Homebrew path rather than using the Apple
Silicon paths below.

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

Phase 5 already supplies the shared PATH helper and source lines. Preserve
`typeset -U path PATH`, which removes duplicate PATH entries. Do not add another
`brew shellenv` or `fnm env` in several files. With the existing fnm selection,
keep its guarded `fnm env --use-on-cd --shell zsh` initialization once in
`.zshrc`; keep another selected Node manager instead if that is your setup.
Use the project's `.node-version`/`.nvmrc` policy to select Node, and confirm
`node --version` after entering each worktree. GUI-launched extensions and MCP
processes do not necessarily run `.zshrc`: a tool working in your terminal does
not prove its executable is available to the extension host.

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
keep the shell plugin. Phase 7's baseline enables the dropdown.

`terminal.external.osxExec` selects Warp for **Open New External Terminal**
(**Shift+Cmd+C**). Warp remains a separate application; it does not replace
the integrated terminal or render inside it. If launching from a folder does
not preserve that folder on your Warp version, open Warp and explicitly
`cd` there. [VS Code terminal basics](https://code.visualstudio.com/docs/terminal/basics).

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

In `.zshrc`, **replace the existing completion/plugin blocks** with the guarded
versions below. Keep your existing PATH, history, fnm, and aliases blocks.
Do not append a second `compinit` or second plugin source line. This example
uses Apple Silicon Homebrew paths; adapt to your installation.

```zsh
# Completion belongs before the Node-manager and prompt initialization.
if [[ ${TERM_PROGRAM:-} != WarpTerminal ]]; then
  for completion_dir in /opt/homebrew/share/zsh/site-functions /opt/homebrew/share/zsh-completions; do
    [[ -d $completion_dir ]] || continue
    (( ${fpath[(Ie)$completion_dir]} )) || fpath=("$completion_dir" $fpath)
  done
  unset completion_dir
  autoload -Uz compinit
  compinit
fi

# Keep the existing fnm and aliases initialization here.

if [[ ${TERM_PROGRAM:-} != WarpTerminal ]]; then
  if [[ -r /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    ZSH_AUTOSUGGEST_STRATEGY=(history)
    source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  fi
fi

# Keep this once if Starship was selected; otherwise omit it.
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# Last plugin integration, after prompt setup and custom ZLE widgets.
if [[ ${TERM_PROGRAM:-} != WarpTerminal ]]; then
  if [[ -r /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
    source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  fi
fi
```

History-only autosuggestions avoid an extra completion strategy. Syntax
highlighting must follow your widget definitions. Preserve existing Docker
completion directories inside the non-Warp completion block.
[Autosuggestions configuration](https://github.com/zsh-users/zsh-autosuggestions),
[syntax-highlighting loading order](https://github.com/zsh-users/zsh-syntax-highlighting).

Keep Phase 5's persistent history settings, once near the top of `.zshrc`:

```zsh
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=10000
setopt APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS HIST_VERIFY
```

This shares recent commands across interactive terminals, reduces duplicate
entries, and lets you inspect a history expansion before running it. If you
prefer arrows to browse only
commands from the current terminal, replace `SHARE_HISTORY` with
`INC_APPEND_HISTORY`; don't enable both. `HIST_IGNORE_SPACE` is an optional
addition that excludes commands beginning with a space from saved history,
but does not prevent other logging. Avoid putting credentials directly into
commands or automatically sourcing every project's `.env` at shell startup.
[Zsh history options](https://zsh.sourceforge.io/Doc/Release/Options.html#History).

### Choose a prompt for Warp

For a consistent Git/Node prompt, retain Starship and select **Shell (PS1)** in
Warp. Merge this optional small configuration into `~/.config/starship.toml`,
updating existing keys rather than duplicating TOML tables:

```toml
add_newline = false
command_timeout = 1000
format = "$directory$git_branch$git_status$nodejs$cmd_duration$line_break$character"

[directory]
truncation_length = 3
truncate_to_repo = true

[line_break]
disabled = false

[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"
```

The prompt shows directory, Git branch/status, Node when relevant, and slow
command duration. The line break gives input its own line; the timeout also
keeps potentially slow Git checks bounded. Large Nx repositories can still
make Git status expensive: disable `[git_status]` if measurements show it is
the bottleneck. [Starship configuration](https://starship.rs/config/).

Use JetBrainsMono Nerd Font in Warp too. Warp documents Starship support with
caveats. Try its native prompt if blocks or agent input behave oddly. If you
prefer Warp's native prompt permanently, guard Starship initialization with
`[[ ${TERM_PROGRAM:-} != WarpTerminal ]]` as well. Add Warp's documented Zsh
newline workaround only if the normal Starship line break fails; do not stack
newline fixes preemptively. Settings labels can move between releases.
[Warp prompt compatibility](https://docs.warp.dev/terminal/appearance/prompt).

### Use terminal shortcuts deliberately

| Action | VS Code on macOS | Warp / shell guidance |
|---|---|---|
| Show integrated terminal | **Ctrl+`** | Warp is a separate app; use your macOS app-switch shortcut |
| New integrated terminal | **Ctrl+Shift+`** | Use Warp's new-tab action; inspect its Keyboard Shortcuts settings |
| Open external terminal | **Shift+Cmd+C** | Opens Warp when configured above |
| Terminal suggestions | **Ctrl+Space** | Use Warp's completion UI; don't bind Tab to `autosuggest-accept` |
| Accept history suggestion | **Right Arrow** with the shell plugin | Right Arrow at the end of input with Warp autosuggestions |
| Search shell history | **Ctrl+R** in a conventional Zsh terminal | Use Warp's history search; its input editor owns key handling |
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
[Warp troubleshooting guide](../apps/WARP.md#troubleshooting) for app-specific issues.
