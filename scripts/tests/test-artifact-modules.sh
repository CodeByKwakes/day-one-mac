#!/usr/bin/env bash
set -euo pipefail
exec </dev/null
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
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
MOCK_READ_ONLY=1 run optional --module 12 --plan --manifest "$TEST_ROOT/profile.tsv" > "$TEST_ROOT/profile-plan"
[[ ! -e "$TEST_STATE" && ! -e "$TEST_STATE.operation.lock" && ! -e "$MOCK_CALLS" ]] || fail 'preview/check mutated state or launched clients'
expect_failure 10 run optional --module 12 --apply --manifest "$TEST_ROOT/profile.tsv" --yes
expect_failure 2 run optional --module 14 --apply --manifest "$TEST_ROOT/profile.tsv" --yes
expect_failure 2 run optional --module 12 --resume --manifest "$TEST_ROOT/profile.tsv"
mkdir -p "$TEST_STATE/completed"
for phase in 01 02 03 04 05 06 07 08; do printf 'fixture\n' > "$TEST_STATE/completed/$phase"; done
run optional --module 12 --apply --manifest "$TEST_ROOT/profile.tsv" --yes > "$TEST_ROOT/profile-apply"
first_profile="$(artifact_path 12)"
python3 -c 'import json,sys; p=json.load(open(sys.argv[1])); assert p["name"]=="Work Review"; assert isinstance(p["extensions"],str); assert json.loads(p["extensions"])==[{"identifier":{"id":"esbenp.prettier-vscode"}}]; assert set(p)=={"name","extensions"}' \
  "$first_profile/profile.code-profile" || fail 'profile structure or embedded extensions are invalid'
[[ "$(wc -l < "$first_profile/extensions.txt" | tr -d ' ')" == 1 ]] || fail 'duplicate extension kept'
printf 'profile\tUnapproved\n' > "$TEST_ROOT/profile.tsv"
run optional --module 12 --resume --yes > "$TEST_ROOT/profile-resume"
[[ "$(artifact_path 12)" != "$first_profile" && -f "$first_profile/profile.code-profile" ]] || fail 'resume overwrote previous artifact'
grep -Fq 'Work Review' "$(artifact_path 12)/profile.code-profile" || fail 'resume reread modified manifest'
cp "$TEST_STATE/artifact-12-current" "$TEST_ROOT/profile-pointer"
before="$(state_hashes)"
MOCK_READ_ONLY=1 run optional --module 12 --check > "$TEST_ROOT/profile-check"
MOCK_READ_ONLY=1 run optional --module 12 --plan > "$TEST_ROOT/profile-plan-saved"
[[ "$before" == "$(state_hashes)" ]] || fail 'plan/check changed existing records'
printf 'tampered\n' >> "$(artifact_path 12)/extensions.txt"
expect_failure 1 run optional --module 12 --check
run optional --module 12 --resume --yes > "$TEST_ROOT/profile-repaired"
printf 'profile\tDefault\n' > "$TEST_ROOT/invalid.tsv"
expect_failure 2 run optional --module 12 --plan --manifest "$TEST_ROOT/invalid.tsv"
printf 'profile\tBad"Name\n' > "$TEST_ROOT/invalid.tsv"
expect_failure 2 run optional --module 12 --plan --manifest "$TEST_ROOT/invalid.tsv"
printf 'profile\tWork\nextension\t--force\n' > "$TEST_ROOT/invalid.tsv"
expect_failure 2 run optional --module 12 --plan --manifest "$TEST_ROOT/invalid.tsv"

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
printf 'core\n' > "$TEST_STATE/preset"
expect_failure 1 run advanced --module 21 --check
run advanced --module 21 --apply --yes > "$TEST_ROOT/audit-accept"
grep -Fq 'selection-preset' "$(artifact_path 21)/report.md" || fail 'audit comparison missing'
[[ -f "$audit_artifact/evidence.tsv" ]] || fail 'old audit snapshot lost'
run advanced --module 21 --check > "$TEST_ROOT/audit-accepted"
mv "$TEST_STATE/completed/01" "$TEST_ROOT/phase01"
expect_failure 1 run advanced --module 21 --apply --yes
grep -Fq $'phase-01-record\tFAIL' "$(artifact_path 21)/evidence.tsv" || fail 'failed evidence not saved'
expect_failure 1 run advanced --module 21 --check
mv "$TEST_ROOT/phase01" "$TEST_STATE/completed/01"
run advanced --module 21 --resume --yes > "$TEST_ROOT/audit-recovered"
run advanced --module 21 --check > "$TEST_ROOT/audit-recovered-check"
run optional --status > "$TEST_ROOT/status"
for id in 12 14 21; do grep -Eq "partial +$id —" "$TEST_ROOT/status" || fail "manual module $id falsely complete"; done
[[ ! -e "$TEST_STATE/advanced/completed/21" && ! -e "$MOCK_CALLS" ]] || fail 'marked guide or launched app'
mkdir "$TEST_STATE.operation.lock"
printf '%s\n' "$$" > "$TEST_STATE.operation.lock/owner"
expect_failure 75 run optional --module 12 --resume --yes
MOCK_READ_ONLY=1 run advanced --module 21 --check > "$TEST_ROOT/locked-check"
rm "$TEST_STATE.operation.lock/owner"
rmdir "$TEST_STATE.operation.lock"
cp "$TEST_STATE/artifact-12-current" "$TEST_ROOT/good-pointer"
printf '../../escape\t%s\n' "$(printf x | shasum -a 256 | awk '{print $1}')" > "$TEST_STATE/artifact-12-current"
expect_failure 1 run optional --module 12 --check
cp "$TEST_ROOT/good-pointer" "$TEST_STATE/artifact-12-current"
ln -s "$TEST_ROOT/profile.tsv" "$(artifact_path 12)/unexpected-link"
expect_failure 1 run optional --module 12 --check
find "$TEST_STATE/module-runs" -name result -exec cat {} + > "$TEST_ROOT/results"
grep -Fxq incomplete "$TEST_ROOT/results" || fail 'failed runs lost'
grep -Fxq verified "$TEST_ROOT/results" || fail 'verified runs missing'
printf 'PASS: write-free plans/checks, immutable exports, recovery, drift, integrity and manual boundaries\n'
