# Review before sourcing. These names do not replace the base shell aliases.
function day_one_cdev() {
  local repo_root
  repo_root="$HOME/Developer"
  [[ -d "$repo_root" ]] || { print -u2 '~/Developer is not a directory'; return 1; }
  builtin cd -- "$repo_root"
}

function day_one_gs() {
  command git status --short --branch
}
