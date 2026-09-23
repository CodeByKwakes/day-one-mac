# Safe, readable aliases selected by Day One Mac.
# Keep destructive, publishing, force-push and prune commands explicit.
if command -v day-one-mac >/dev/null 2>&1; then
  alias cdayone='cd "$(day-one-mac root)"'
fi

if command -v git >/dev/null 2>&1; then
  alias gs='git status --short --branch'
  alias gd='git diff'
  alias gds='git diff --staged'
  alias gl='git log --oneline --graph --decorate -20'
  alias gremotes='git remote --verbose'
fi

if command -v chezmoi >/dev/null 2>&1; then
  alias cm='chezmoi'
  alias cmstatus='chezmoi status'
  alias cmdiff='chezmoi diff --no-pager'
  alias cmverify='chezmoi verify'
  alias cmdoctor='chezmoi doctor'
fi

if command -v brew >/dev/null 2>&1; then
  alias brewcheck='brew bundle check --file="$HOME/Brewfile" --no-upgrade'
  alias brewout='brew outdated --greedy'
  alias brewcleanpreview='brew cleanup --dry-run'
  alias brewautopreview='brew autoremove --dry-run'
fi
