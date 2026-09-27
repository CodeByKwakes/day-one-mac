#!/usr/bin/env bash
set -euo pipefail
exec </dev/null
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEST_ROOT="$(mktemp -d /tmp/day-one-module-execution.XXXXXX)"
trap 'rm -rf "$TEST_ROOT"' EXIT
MOCK_BIN="$TEST_ROOT/bin"
MOCK_INSTALLED="$TEST_ROOT/installed"
MOCK_CALLS="$TEST_ROOT/calls"
TEST_STATE="$TEST_ROOT/state"
export MOCK_INSTALLED MOCK_CALLS
mkdir "$MOCK_BIN"
printf 'fzf\n' > "$MOCK_INSTALLED"
cat > "$MOCK_BIN/brew" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >> "$MOCK_CALLS"
case "$1" in
  list)
    [[ "${MOCK_INVENTORY_FAIL:-0}" == 0 ]] || exit 1
    cat "$MOCK_INSTALLED" ;;
  install)
    if [[ "${MOCK_FAIL_PACKAGE:-}" == "$2" ]]; then
      printf 'fixture-dependency\n' >> "$MOCK_INSTALLED"
      exit 7
    fi
    printf '%s\n' "$2" >> "$MOCK_INSTALLED" ;;
  *) exit 99 ;;
esac
EOF
chmod +x "$MOCK_BIN/brew"
fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
run_module() {
  env DAY_ONE_MAC_STATE_ROOT="$TEST_STATE" DAY_ONE_MAC_STATE_DIR="$TEST_STATE" \
    PATH="$MOCK_BIN:/usr/bin:/bin" NO_COLOR=1 \
    "$SCRIPT_DIR/day-one-mac" optional "$@"
}
expect_failure() {
  local expected="$1" actual=0
  shift
  "$@" > "$TEST_ROOT/error" 2>&1 || actual=$?
  [[ "$actual" == "$expected" ]] || fail "expected exit $expected, got $actual"
}

# Registry is data, with fixed IDs and real installed guide paths.
awk -F '\t' '!/^#/ {if (NF != 6 || seen[$1]++ || ($3 != "guided" && $3 != "executable") || $4 != "08") exit 1; count++} END {if (count != 15) exit 1}' \
  "$PROJECT_DIR/config/modules.tsv" || fail 'invalid registry'
while IFS=$'\t' read -r id layer mode prerequisite title guide; do
  [[ "$id" != \#* ]] || continue
  [[ -r "$PROJECT_DIR/$guide" ]] || fail "missing guide: $guide"
done < "$PROJECT_DIR/config/modules.tsv"
run_module --list > "$TEST_ROOT/list"
grep -Fq $'09\toptional\texecutable' "$TEST_ROOT/list" || fail 'missing database capability'
grep -Fq $'22\tadvanced\tguided' "$TEST_ROOT/list" || fail 'advanced capability is misleading'
run_module --module 13 --plan --packages eza,fzf > "$TEST_ROOT/plan"
grep -Fq 'brew install eza' "$TEST_ROOT/plan" || fail 'missing plan operation'
[[ ! -e "$TEST_STATE" && ! -e "$TEST_STATE.operation.lock" ]] || fail 'plan created state/lock'
if grep -q '^install ' "$MOCK_CALLS"; then fail 'plan installed packages'; fi
expect_failure 10 run_module --module 13 --apply --packages eza --yes
expect_failure 2 run_module --module 13 --plan --apply --packages eza
expect_failure 2 run_module --module 13 --resume --packages eza
expect_failure 2 run_module --module 13 --plan --services postgres
expect_failure 2 run_module --module 13 --check
expect_failure 2 run_module --module 11 --apply
expect_failure 2 run_module --module 20 --apply
expect_failure 2 run_module --module ../09 --plan
[[ ! -e "$TEST_STATE" ]] || fail 'invalid request saved state'

# Test prerequisite markers are confined to this disposable fixture.
mkdir -p "$TEST_STATE/completed"
printf 'fixture\n' > "$TEST_STATE/completed/08"
run_module --module 13 --apply --packages eza,fzf --yes > "$TEST_ROOT/apply"
grep -Fxq 'eza,fzf' "$TEST_STATE/optional-cli-packages" || fail 'selection not saved'
grep -Fxq $'brew-formula\teza' "$TEST_STATE/install-manifest.tsv" || fail 'new installation not owned'
if grep -q fzf "$TEST_STATE/install-manifest.tsv"; then fail 'preexisting package claimed as owned'; fi
run_module --module 13 --check > "$TEST_ROOT/check"
run_module --module 13 --resume --yes > "$TEST_ROOT/resume"
[[ "$(grep -c '^install eza$' "$MOCK_CALLS")" == 1 ]] || fail 'resume reinstalled package'
[[ ! -e "$TEST_STATE.operation.lock" ]] || fail 'apply left lock'
find "$TEST_STATE/module-runs/13" -name result -exec grep -L '^verified$' {} + > "$TEST_ROOT/unverified"
[[ ! -s "$TEST_ROOT/unverified" ]] || fail 'successful apply not verified'

MOCK_FAIL_PACKAGE=bat expect_failure 7 run_module --module 13 --apply --packages bat,zoxide --yes
grep -Fxq 'bat,zoxide' "$TEST_STATE/optional-cli-packages" || fail 'failed selection not resumable'
grep -Fxq $'brew-dependency\tfixture-dependency' "$TEST_STATE/install-manifest.tsv" || fail 'partial additions not recorded'
expect_failure 1 run_module --module 13 --check
run_module --module 13 --resume --yes > "$TEST_ROOT/recovery"
run_module --module 13 --check > "$TEST_ROOT/recovered-check"
[[ "$(grep -c '^install zoxide$' "$MOCK_CALLS")" == 1 ]] || fail 'resume did not finish remaining package'
find "$TEST_STATE/module-runs/13" -name backups.tsv -exec cat {} + > "$TEST_ROOT/backups"
grep -Fq "$TEST_STATE/optional-cli-packages" "$TEST_ROOT/backups" || fail 'previous selection not backed up'
find "$TEST_STATE/module-runs/13" -name result -exec cat {} + > "$TEST_ROOT/results"
grep -Fxq incomplete "$TEST_ROOT/results" || fail 'failed run claimed success'

mkdir "$TEST_STATE.operation.lock"
printf '%s\n' "$$" > "$TEST_STATE.operation.lock/owner"
expect_failure 75 run_module --module 13 --resume --yes
run_module --module 13 --plan > "$TEST_ROOT/locked-plan"
run_module --module 13 --check > "$TEST_ROOT/locked-check"
rm "$TEST_STATE.operation.lock/owner"
rmdir "$TEST_STATE.operation.lock"
MOCK_INVENTORY_FAIL=1 expect_failure 1 run_module --module 13 --plan

# A state symlink must not turn an apply into an unrelated file overwrite.
mv "$TEST_STATE/install-manifest.tsv" "$TEST_ROOT/manifest-original"
ln -s "$TEST_ROOT/manifest-original" "$TEST_STATE/install-manifest.tsv"
expect_failure 1 run_module --module 13 --resume --yes
[[ -L "$TEST_STATE/install-manifest.tsv" ]] || fail 'state symlink replaced'
printf 'PASS: module registry, preview, apply, check, resume, ownership, backups and locks\n'
