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
