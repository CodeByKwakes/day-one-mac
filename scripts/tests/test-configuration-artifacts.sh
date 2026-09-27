#!/usr/bin/env bash
set -euo pipefail
exec </dev/null
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
command -v node >/dev/null 2>&1 || { printf 'Contributor fixture requires Node 22+ on PATH.\n' >&2; exit 1; }
TEST_ROOT="$(mktemp -d /private/tmp/day-one-configuration.XXXXXX)"
trap 'rm -rf "$TEST_ROOT"' EXIT
TEST_STATE="$TEST_ROOT/state"
TEST_HOME="$TEST_ROOT/home"
MOCK_CALLS="$TEST_ROOT/forbidden-calls"
export MOCK_CALLS
mkdir -p "$TEST_HOME/.config/zsh" "$TEST_ROOT/source/dot_config/zsh" "$TEST_ROOT/project" "$TEST_ROOT/bin"
for executable in chezmoi npm pnpm brew defaults; do
  cat > "$TEST_ROOT/bin/$executable" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$0 $*" >> "$MOCK_CALLS"
exit 99
MOCK
done
chmod +x "$TEST_ROOT/bin/"*
run() { env HOME="$TEST_HOME" PATH="$TEST_ROOT/bin:$PATH" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE" DAY_ONE_MAC_STATE_DIR="$TEST_STATE" "$SCRIPT_DIR/day-one-mac" "$@"; }
fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
expect_failure() {
  local expected="$1" actual=0
  shift
  "$@" > "$TEST_ROOT/error" 2>&1 || actual=$?
  [[ "$actual" == "$expected" ]] || { cat "$TEST_ROOT/error"; fail "expected $expected got $actual"; }
}
artifact() { printf '%s/module-runs/%s/%s/artifact\n' "$TEST_STATE" "$1" "$(cut -f 1 "$TEST_STATE/artifact-$1-current")"; }
printf 'private-canary-do-not-copy\n' > "$TEST_HOME/.config/zsh/aliases.zsh"
printf '{{ output "touch" "/never-run-a-template" }}\n' > "$TEST_ROOT/source/dot_config/zsh/aliases.zsh.tmpl"
printf 'aliases\tchezmoi\t%s/source/dot_config/zsh/aliases.zsh.tmpl\n' "$TEST_ROOT" > "$TEST_ROOT/dotfiles.tsv"
run advanced --module 15 --plan --manifest "$TEST_ROOT/dotfiles.tsv" > "$TEST_ROOT/plan"
[[ ! -e "$TEST_STATE" && ! -e "$TEST_STATE.operation.lock" ]] || fail 'plan created state'
expect_failure 10 run advanced --module 15 --apply --manifest "$TEST_ROOT/dotfiles.tsv" --yes
mkdir -p "$TEST_STATE/completed"
printf fixture > "$TEST_STATE/completed/08"
run advanced --module 15 --apply --manifest "$TEST_ROOT/dotfiles.tsv" --yes > "$TEST_ROOT/apply"
first="$(artifact 15)"
[[ -f "$first/import-proposal.tsv" ]] || fail 'proposal missing'
run advanced --module 15 --check > "$TEST_ROOT/check"
printf changed >> "$TEST_HOME/.config/zsh/aliases.zsh"
expect_failure 1 run advanced --module 15 --check
run advanced --module 15 --resume --yes > "$TEST_ROOT/resume"
[[ "$(artifact 15)" != "$first" && -f "$first/evidence.tsv" ]] || fail 'old snapshot lost'
printf 'ssh-key\tmanual\t-\n' > "$TEST_ROOT/bad.tsv"
expect_failure 2 run advanced --module 15 --plan --manifest "$TEST_ROOT/bad.tsv"
mv "$TEST_HOME/.config/zsh/aliases.zsh" "$TEST_ROOT/aliases"
ln -s "$TEST_ROOT/aliases" "$TEST_HOME/.config/zsh/aliases.zsh"
expect_failure 1 run advanced --module 15 --resume --yes
grep -q $'\tFAIL\t' "$(artifact 15)/evidence.tsv" || fail 'unsafe input not recorded'
rm "$TEST_HOME/.config/zsh/aliases.zsh"
mv "$TEST_ROOT/aliases" "$TEST_HOME/.config/zsh/aliases.zsh"
run advanced --module 15 --resume --yes > "$TEST_ROOT/recovered"
printf '{"packageManager":"npm@10.0.0","scripts":{"install":"touch NEVER_RUN"}}\n' > "$TEST_ROOT/project/package.json"
printf '{}\n' > "$TEST_ROOT/project/package-lock.json"
printf 'helper\tnavigation\nhelper\tpackages\nproject\t%s/project\n' "$TEST_ROOT" > "$TEST_ROOT/helpers.tsv"
run advanced --module 17 --plan --manifest "$TEST_ROOT/helpers.tsv" > "$TEST_ROOT/helper-plan"
run advanced --module 17 --apply --manifest "$TEST_ROOT/helpers.tsv" --yes > "$TEST_ROOT/helper-apply"
helpers="$(artifact 17)"
[[ -f "$helpers/navigation.zsh" && -f "$helpers/packages.zsh" ]] || fail 'helper bundle incomplete'
run advanced --module 17 --check > "$TEST_ROOT/helper-check"
printf 'require("node:fs").writeFileSync(process.env.MOCK_CALLS, "preload executed");\n' > "$TEST_ROOT/preload.cjs"
NODE_OPTIONS="--require=$TEST_ROOT/preload.cjs" NODE_V8_COVERAGE="$TEST_ROOT/coverage" \
  NODE_COMPILE_CACHE="$TEST_ROOT/compile-cache" run advanced --module 17 --check > "$TEST_ROOT/environment-check"
[[ ! -e "$TEST_ROOT/coverage" && ! -e "$TEST_ROOT/compile-cache" && ! -e "$MOCK_CALLS" ]] || fail 'Node preload/coverage/cache environment escaped read-only inspection'
env PATH="$TEST_ROOT/bin:$PATH" ZDOTDIR=/dev/null zsh -dfc 'source "$1"; cd -- "$2"; day_one_pm_frozen_plan' _ "$helpers/packages.zsh" "$TEST_ROOT/project" > "$TEST_ROOT/frozen"
grep -Fq 'npm ci' "$TEST_ROOT/frozen" || fail 'wrong frozen proposal'
printf 'lockfileVersion: 9\n' > "$TEST_ROOT/project/pnpm-lock.yaml"
expect_failure 1 run advanced --module 17 --check
expect_failure 1 run advanced --module 17 --resume --yes
[[ ! -e "$(artifact 17)/packages.zsh" ]] || fail 'failed validation published an activatable bundle'
rm "$TEST_ROOT/project/package-lock.json"
printf '{"packageManager":"pnpm@10.0.0"}\n' > "$TEST_ROOT/project/package.json"
run advanced --module 17 --resume --yes > "$TEST_ROOT/helper-resume"
run advanced --module 17 --check > "$TEST_ROOT/helper-recheck"
ln -s "$TEST_ROOT/aliases" "$TEST_ROOT/project/yarn.lock"
expect_failure 1 run advanced --module 17 --check
rm "$TEST_ROOT/project/yarn.lock"
printf '{"packageManager":"yarn@4.0.0"}\n' > "$TEST_ROOT/project/package.json"
expect_failure 1 run advanced --module 17 --check
printf '{"packageManager":"pnpm@10.0.0"}\n' > "$TEST_ROOT/project/package.json"
before="$(find "$TEST_STATE" -type f -exec shasum -a 256 {} + | sort)"
run advanced --module 17 --plan > "$TEST_ROOT/helper-readonly-plan"
run advanced --module 17 --check > "$TEST_ROOT/helper-readonly-check"
run optional --status > "$TEST_ROOT/dashboard"
for id in 15 17; do grep -Eq "partial +$id —" "$TEST_ROOT/dashboard" || fail "false completion of $id"; done
[[ "$before" == "$(find "$TEST_STATE" -type f -exec shasum -a 256 {} + | sort)" ]] || fail 'read-only operations changed state'
[[ ! -e "$MOCK_CALLS" && ! -e "$TEST_ROOT/project/NEVER_RUN" ]] || fail 'installer, preference, chezmoi or project script executed'
if grep -Rq private-canary-do-not-copy "$TEST_STATE"; then fail 'dotfile contents copied'; fi
printf 'PASS: explicit dotfile evidence, no secret copying, shell bundles, package conflicts and manual activation boundaries\n'
