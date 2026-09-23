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
