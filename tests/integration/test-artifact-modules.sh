#!/usr/bin/env bash
set -euo pipefail
exec </dev/null
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)"
TEST_ROOT="$(mktemp -d /private/tmp/day-one-artifacts.XXXXXX)"
trap 'rm -rf "$TEST_ROOT"' EXIT
TEST_STATE="$TEST_ROOT/state"
MOCK_BIN="$TEST_ROOT/bin"
MOCK_CALLS="$TEST_ROOT/calls"
export MOCK_CALLS
mkdir "$MOCK_BIN"
cat > "$MOCK_BIN/cp" <<'EOF'
#!/usr/bin/env bash
if [[ "${MOCK_COPY_FAIL:-0}" == 1 && "$1" == -R ]]; then exit 7; fi
exec /bin/cp "$@"
EOF
cat > "$MOCK_BIN/mktemp" <<'EOF'
#!/usr/bin/env bash
[[ "${MOCK_READ_ONLY:-0}" == 0 ]] || { printf 'temporary write attempted\n' >> "$MOCK_CALLS"; exit 99; }
exec /usr/bin/mktemp "$@"
EOF
for command in code open brew claude codex gh az; do
  cat > "$MOCK_BIN/$command" <<'EOF'
#!/usr/bin/env bash
printf 'unexpected application command: %s\n' "$0 $*" >> "$MOCK_CALLS"
exit 99
EOF
done
chmod +x "$MOCK_BIN/"*
run() {
  env PATH="$MOCK_BIN:/usr/bin:/bin" NO_COLOR=1 \
    DAY_ONE_MAC_STATE_ROOT="$TEST_STATE" DAY_ONE_MAC_STATE_DIR="$TEST_STATE" \
    DAY_ONE_MAC_APPLICATION_BREW_LOOKUP=disabled "$SCRIPT_DIR/day-one-mac" "$@"
}
fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
expect_failure() {
  local expected="$1" actual=0
  shift
  "$@" > "$TEST_ROOT/error" 2>&1 || actual=$?
  [[ "$actual" == "$expected" ]] || { cat "$TEST_ROOT/error" >&2; fail "expected $expected got $actual"; }
}
artifact_path() {
  local id="$1" run_id
  run_id="$(cut -f 1 "$TEST_STATE/artifact-$id-current")"
  printf '%s/module-runs/%s/%s/artifact\n' "$TEST_STATE" "$id" "$run_id"
}
state_hashes() {
  find "$TEST_STATE" -type f -exec shasum -a 256 {} + | LC_ALL=C sort
}
printf 'profile\tWork Review\nextension\tesbenp.prettier-vscode\nextension\tesbenp.prettier-vscode\n' > "$TEST_ROOT/profile.tsv"
for id in 14 21; do
  MOCK_READ_ONLY=1 run advanced --module "$id" --plan > "$TEST_ROOT/plan-$id"
  expect_failure 1 run advanced --module "$id" --check
done
# Retired calls must be inert even with old selections, invalid manifests or locks.
for action in plan apply check resume; do
  expect_failure 2 run optional --module 12 "--$action"
  grep -Fq 'day-one-mac vscode-profile full-stack --dry-run' "$TEST_ROOT/error" || fail 'retirement guidance missing'
done
expect_failure 2 run optional --module 12
[[ ! -e "$TEST_STATE" && ! -e "$TEST_STATE.operation.lock" && ! -e "$MOCK_CALLS" ]] || fail 'retired command created state or launched clients'
expect_failure 2 run optional --module 14 --apply --manifest "$TEST_ROOT/profile.tsv" --yes
mkdir -p "$TEST_STATE/module-runs/12/legacy/artifact"
printf 'vscode-profiles\n' > "$TEST_STATE/optional-modules"
printf 'profile\tWork Review\n' > "$TEST_STATE/artifact-12-selection.tsv"
printf 'legacy-pointer\n' > "$TEST_STATE/artifact-12-current"
printf '{"name":"Work Review","extensions":"[]"}\n' > "$TEST_STATE/module-runs/12/legacy/artifact/profile.code-profile"
before="$(state_hashes)"
for action in plan apply check resume; do
  expect_failure 2 run optional --module 12 "--$action" --manifest "$TEST_ROOT/missing.tsv"
  expect_failure 2 env DAY_ONE_MAC_STATE_ROOT="$TEST_STATE" DAY_ONE_MAC_STATE_DIR="$TEST_STATE" \
    PATH="$MOCK_BIN:/usr/bin:/bin" "$SCRIPT_DIR/../src/modules/configure-artifacts.sh" --module 12 "--$action"
done
MOCK_READ_ONLY=1 run optional --status --check > "$TEST_ROOT/retired-status"
if grep -Eq ' +12 —' "$TEST_ROOT/retired-status"; then fail 'retired profile counted as active'; fi
grep -Fq 'Optional phase: not complete (0/6 modules ready)' "$TEST_ROOT/retired-status" || fail 'optional group count includes retired module'
grep -Fq 'Advanced phase: not complete (0/8 modules ready)' "$TEST_ROOT/retired-status" || fail 'advanced group count shifted incorrectly'
[[ "$before" == "$(state_hashes)" && ! -e "$MOCK_CALLS" ]] || fail 'retired calls changed old artifacts or launched clients'
"$SCRIPT_DIR/../tests/integration/seed-required-state.sh" "$TEST_STATE"

MOCK_COPY_FAIL=1 expect_failure 7 run optional --module 14 --apply --yes
[[ -s "$TEST_STATE/artifact-14-selection.tsv" && ! -e "$TEST_STATE/artifact-14-current" ]] || fail 'failed export published incomplete artifact or lost recovery selection'
run optional --module 14 --resume --yes > "$TEST_ROOT/warp-resume"
warp_artifact="$(artifact_path 14)"
[[ "$(find "$warp_artifact/Day One Mac" -type f -name '*.yaml' | wc -l | tr -d ' ')" == 63 ]] || fail 'incomplete Warp export'
MOCK_READ_ONLY=1 run optional --module 14 --check > "$TEST_ROOT/warp-check"
cp "$TEST_STATE/artifact-14-current" "$TEST_ROOT/warp-pointer"
MOCK_COPY_FAIL=1 expect_failure 7 run optional --module 14 --resume --yes
cmp "$TEST_STATE/artifact-14-current" "$TEST_ROOT/warp-pointer" || fail 'failed resume replaced published pointer'
run optional --module 14 --check > "$TEST_ROOT/warp-still-current"
printf 'extra\n' > "$warp_artifact/unexpected.txt"
expect_failure 1 run optional --module 14 --check
run optional --module 14 --resume --yes > "$TEST_ROOT/warp-repaired"
before="$(state_hashes)"
MOCK_READ_ONLY=1 run optional --module 14 --plan > "$TEST_ROOT/warp-plan"
MOCK_READ_ONLY=1 run optional --module 14 --check > "$TEST_ROOT/warp-read-only-check"
[[ "$before" == "$(state_hashes)" ]] || fail 'artifact plan/check changed existing records'
# A changed runtime source requires new approval, not silent resume.
cp "$TEST_STATE/artifact-14-selection.tsv" "$TEST_ROOT/warp-selection"
printf 'warp-v1\told-source\n' > "$TEST_STATE/artifact-14-selection.tsv"
expect_failure 1 run optional --module 14 --resume --yes
cp "$TEST_ROOT/warp-selection" "$TEST_STATE/artifact-14-selection.tsv"

run advanced --module 21 --apply --yes > "$TEST_ROOT/audit-apply"
audit_artifact="$(artifact_path 21)"
[[ -f "$audit_artifact/report.md" && -f "$audit_artifact/evidence.tsv" ]] || fail 'audit output missing'
before="$(state_hashes)"
MOCK_READ_ONLY=1 run advanced --module 21 --check > "$TEST_ROOT/audit-check"
MOCK_READ_ONLY=1 run advanced --module 21 --plan > "$TEST_ROOT/audit-plan"
[[ "$before" == "$(state_hashes)" ]] || fail 'audit preview/check wrote records'
printf 'recommended-productivity\n' > "$TEST_STATE/preset"
expect_failure 1 run advanced --module 21 --check
"$SCRIPT_DIR/../tests/integration/seed-required-state.sh" "$TEST_STATE"
run advanced --module 21 --apply --yes > "$TEST_ROOT/audit-accept"
grep -Fq 'selection-preset' "$(artifact_path 21)/report.md" || fail 'audit comparison missing'
[[ -f "$audit_artifact/evidence.tsv" ]] || fail 'old audit snapshot lost'
run advanced --module 21 --check > "$TEST_ROOT/audit-accepted"
mv "$TEST_STATE/completed/01" "$TEST_ROOT/phase01"
run advanced --module 21 --apply --yes > "$TEST_ROOT/audit-no-legacy-marker"
grep -Fq $'phase-01-record\tINFO' "$(artifact_path 21)/evidence.tsv" || fail 'missing legacy record was not informational'
run advanced --module 21 --check > "$TEST_ROOT/audit-check-no-marker"
mv "$TEST_ROOT/phase01" "$TEST_STATE/completed/01"
run advanced --module 21 --resume --yes > "$TEST_ROOT/audit-recovered"
run advanced --module 21 --check > "$TEST_ROOT/audit-recovered-check"
run optional --status > "$TEST_ROOT/status"
for id in 14 21; do grep -Eq "partial +$id —" "$TEST_ROOT/status" || fail "manual module $id falsely complete"; done
[[ ! -e "$TEST_STATE/advanced/completed/21" && ! -e "$MOCK_CALLS" ]] || fail 'marked guide or launched app'
mkdir "$TEST_STATE.operation.lock"
printf '%s\n' "$$" > "$TEST_STATE.operation.lock/owner"
expect_failure 2 run optional --module 12 --resume --yes
expect_failure 75 run optional --module 14 --resume --yes
MOCK_READ_ONLY=1 run advanced --module 21 --check > "$TEST_ROOT/locked-check"
rm "$TEST_STATE.operation.lock/owner"
rmdir "$TEST_STATE.operation.lock"
cp "$TEST_STATE/artifact-14-current" "$TEST_ROOT/good-pointer"
printf '../../escape\t%s\n' "$(printf x | shasum -a 256 | awk '{print $1}')" > "$TEST_STATE/artifact-14-current"
expect_failure 1 run optional --module 14 --check
cp "$TEST_ROOT/good-pointer" "$TEST_STATE/artifact-14-current"
ln -s "$TEST_ROOT/profile.tsv" "$(artifact_path 14)/unexpected-link"
expect_failure 1 run optional --module 14 --check
find "$TEST_STATE/module-runs" -name result -exec cat {} + > "$TEST_ROOT/results"
grep -Fxq incomplete "$TEST_ROOT/results" || fail 'failed runs lost'
grep -Fxq verified "$TEST_ROOT/results" || fail 'verified runs missing'
printf 'PASS: write-free plans/checks, immutable exports, recovery, drift, integrity and manual boundaries\n'
