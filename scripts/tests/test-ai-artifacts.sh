#!/usr/bin/env bash
set -euo pipefail
exec </dev/null
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d /private/tmp/day-one-ai-artifacts.XXXXXX)"
trap 'rm -rf "$TEST_ROOT"' EXIT
TEST_STATE="$TEST_ROOT/state"
run() {
  env DAY_ONE_MAC_STATE_ROOT="$TEST_STATE" DAY_ONE_MAC_STATE_DIR="$TEST_STATE" \
    DAY_ONE_MCP_TEST=super-secret-value "$SCRIPT_DIR/day-one-mac" "$@"
}
fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
expect_failure() {
  local expected="$1" actual=0
  shift
  "$@" > "$TEST_ROOT/error" 2>&1 || actual=$?
  [[ "$actual" == "$expected" ]] || { cat "$TEST_ROOT/error"; fail "expected $expected got $actual"; }
}
artifact() {
  printf '%s/module-runs/%s/%s/artifact\n' "$TEST_STATE" "$1" "$(cut -f 1 "$TEST_STATE/artifact-$1-current")"
}
printf 'claude\texample\tworkspace\thttps://mcp.example.com/mcp\tDAY_ONE_MCP_TEST\ncodex\texample\tworkspace\thttps://mcp.example.com/mcp\tDAY_ONE_MCP_TEST\nvscode\tpublic\tworkspace\thttps://mcp.example.com/mcp\t-\nvscode\tprivate\tworkspace\thttps://mcp.example.com/mcp\tDAY_ONE_MCP_TEST\n' > "$TEST_ROOT/mcp.tsv"
run optional --module 11 --plan --manifest "$TEST_ROOT/mcp.tsv" > "$TEST_ROOT/plan"
[[ ! -e "$TEST_STATE" && ! -e "$TEST_STATE.operation.lock" ]] || fail 'plan wrote state'
if grep -q super-secret-value "$TEST_ROOT/plan"; then fail 'token value leaked'; fi
expect_failure 10 run optional --module 11 --apply --manifest "$TEST_ROOT/mcp.tsv" --yes
mkdir -p "$TEST_STATE/completed" "$TEST_ROOT/skill"
printf fixture > "$TEST_STATE/completed/08"
printf '# Test skill\nNever run me.\n' > "$TEST_ROOT/skill/SKILL.md"
run optional --module 11 --apply --manifest "$TEST_ROOT/mcp.tsv" --yes > "$TEST_ROOT/apply"
first="$(artifact 11)"
python3 -c 'import json,sys; p=json.load(open(sys.argv[1])); assert p["mcpServers"]["example"]["headers"]["Authorization"]=="Bearer ${DAY_ONE_MCP_TEST}"; p=json.load(open(sys.argv[2])); assert "headers" not in p["servers"]["public"]; assert p["servers"]["private"]["headers"]["Authorization"]=="Bearer ${env:DAY_ONE_MCP_TEST}"' \
  "$first/claude-mcp.json" "$first/vscode-mcp.json"
grep -Fxq 'enabled = false' "$first/codex-mcp.toml" || fail 'Codex activated'
grep -Fxq 'bearer_token_env_var = "DAY_ONE_MCP_TEST"' "$first/codex-mcp.toml" || fail 'wrong token field'
printf invalid > "$TEST_ROOT/mcp.tsv"
run optional --module 11 --resume --yes > "$TEST_ROOT/resume"
[[ "$(artifact 11)" != "$first" && -f "$first/claude-mcp.json" ]] || fail 'old version overwritten'
before="$(find "$TEST_STATE" -type f -exec shasum -a 256 {} + | sort)"
run optional --module 11 --check > "$TEST_ROOT/check"
[[ "$before" == "$(find "$TEST_STATE" -type f -exec shasum -a 256 {} + | sort)" ]] || fail 'check wrote records'
printf tamper >> "$(artifact 11)/codex-mcp.toml"
expect_failure 1 run optional --module 11 --check
run optional --module 11 --resume --yes > "$TEST_ROOT/repair"
for row in \
  $'codex\tbad\tuser\thttps://mcp.example.com\t-' \
  $'codex\tbad\tworkspace\thttps://user:pass@example.com\t-' \
  $'codex\tbad\tworkspace\thttps://example.com?token=secret\t-' \
  $'codex\tbad\tworkspace\thttps://example.com\tOPENAI_API_KEY' \
  $'codex\tbad\tworkspace\thttps://example.com\tactual-secret' \
  $'codex\tbad\tworkspace\thttps://example.com\t-\textra' \
  $'codex\tbad\tworkspace\thttps://example.com\t-\n'; do
  printf '%s\n' "$row" > "$TEST_ROOT/invalid.tsv"
  # Empty trailing lines are valid; test duplicate entries instead for last row.
  [[ "$row" != *$'\n' ]] || printf '%s' "$row" >> "$TEST_ROOT/invalid.tsv"
  expect_failure 2 run optional --module 11 --plan --manifest "$TEST_ROOT/invalid.tsv"
done
cp "$TEST_STATE/artifact-11-selection.tsv" "$TEST_ROOT/mcp.tsv"
printf 'skill\ttest-skill\tteam-a\t%s/skill\nmcp\ttest-mcp\tteam-a\t%s/mcp.tsv\n' "$TEST_ROOT" "$TEST_ROOT" > "$TEST_ROOT/governance.tsv"
run advanced --module 22 --plan --manifest "$TEST_ROOT/governance.tsv" > "$TEST_ROOT/governance-plan"
run advanced --module 22 --apply --manifest "$TEST_ROOT/governance.tsv" --yes > "$TEST_ROOT/governance-apply"
run advanced --module 22 --check > "$TEST_ROOT/governance-check"
run optional --status > "$TEST_ROOT/dashboard"
for id in 11 22; do
  grep -Eq "partial +$id —" "$TEST_ROOT/dashboard" || fail "module $id falsely complete or not selected"
done
run advanced --module 21 --plan > "$TEST_ROOT/audit-plan"
for id in 11 22; do
  grep -Fq "module-$id"$'\tPASS\t' "$TEST_ROOT/audit-plan" || fail "audit omitted module $id"
done
printf '\nChanged\n' >> "$TEST_ROOT/skill/SKILL.md"
expect_failure 1 run advanced --module 22 --check
run optional --status > "$TEST_ROOT/drift-dashboard"
grep -Eq 'review +22 —' "$TEST_ROOT/drift-dashboard" || fail 'dashboard missed governance drift'
run advanced --module 22 --plan > "$TEST_ROOT/drift"
grep -q '^[-+]skill' "$TEST_ROOT/drift" || fail 'drift not shown'
run advanced --module 22 --resume --yes > "$TEST_ROOT/new-baseline"
run advanced --module 22 --check > "$TEST_ROOT/new-check"
ln -s "$TEST_ROOT/mcp.tsv" "$TEST_ROOT/skill/unsafe-link"
expect_failure 1 run advanced --module 22 --resume --yes
grep -q $'\tFAIL\t' "$(artifact 22)/evidence.tsv" || fail 'failure snapshot not retained'
expect_failure 1 run advanced --module 22 --check
printf 'skill\ttoo-wide\tteam-a\t/\n' > "$TEST_ROOT/invalid.tsv"
expect_failure 2 run advanced --module 22 --plan --manifest "$TEST_ROOT/invalid.tsv"
if grep -R -q super-secret-value "$TEST_STATE"; then fail 'secret persisted'; fi
[[ ! -e "$TEST_STATE.operation.lock" ]] || fail 'lock leaked'
# A failed checksum must never become PASS even inside a conditional caller.
evidence="$(bash -c '
  set -euo pipefail
  source "$1"
  SELECTION=$'"'"'mcp\tfixture\towner\t/unused'"'"'
  day_one_mcp_selection() { printf metadata; }
  shasum() { return 1; }
  day_one_governance_evidence
' _ "$SCRIPT_DIR/lib/ai-artifacts.sh")"
grep -q $'\tFAIL\tunavailable' <<< "$evidence" || fail 'checksum failure falsely passed'
printf 'PASS: MCP schemas/placeholders, immutable versions, governance ownership/drift and unsafe-input rejection\n'
