#!/usr/bin/env bash
set -euo pipefail
exec </dev/null
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d /tmp/day-one-software-test.XXXXXX)"
trap 'rm -rf "$TEST_ROOT"' EXIT
MOCK_BIN="$TEST_ROOT/bin"
MOCK_DATA="$TEST_ROOT/data"
TEST_STATE="$TEST_ROOT/state"
export MOCK_BIN MOCK_DATA
mkdir -p "$MOCK_BIN" "$MOCK_DATA"
printf 'git\n' > "$MOCK_DATA/formulae"
: > "$MOCK_DATA/casks"
printf 'example.existing@1.0.0\n' > "$MOCK_DATA/extensions"
printf 'Example.MixedCase@2.0.0\n' >> "$MOCK_DATA/extensions"
cat > "$TEST_ROOT/apps.tsv" <<'EOF'
# id	scope	phase	name	homebrew_cask	kind	expected_path	bundle_id	command
claude-code	optional	10	Claude Code	claude-code	cli	-	-	claude
codex	optional	10	Codex	codex	cli	-	-	codex
raycast	required	04	Raycast	raycast	cli	-	-	raycast
visual-studio-code	required	04	VS Code	visual-studio-code	cli	-	-	code
EOF
cat > "$MOCK_BIN/claude" <<'EOF'
#!/usr/bin/env bash
printf 'FAIL: runner must not launch AI clients or auth commands\n' >&2
exit 99
EOF
cat > "$MOCK_BIN/brew" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'brew %s\n' "$*" >> "$MOCK_DATA/calls"
case "$1 $2" in
  'list --formula')
    [[ "${MOCK_BREW_FAIL:-0}" == 0 ]] || exit 1
    cat "$MOCK_DATA/formulae" ;;
  'list --cask')
    if [[ "${3:-}" == --versions ]]; then awk '{print $1 " 1.2.3"}' "$MOCK_DATA/casks"
    elif [[ -n "${3:-}" ]]; then grep -Fxq "$3" "$MOCK_DATA/casks"
    else cat "$MOCK_DATA/casks"; fi ;;
  'install --cask'|'install --formula')
    if [[ "${MOCK_INSTALL_FAIL:-}" == "$3" ]]; then
      printf 'fixture-dependency\n' >> "$MOCK_DATA/formulae"
      exit 7
    fi
    if [[ "$2" == --formula ]]; then printf '%s\n' "$3" >> "$MOCK_DATA/formulae"
    else
      printf '%s\n' "$3" >> "$MOCK_DATA/casks"
      printf '#!/usr/bin/env bash\nexit 0\n' > "$MOCK_BIN/$3"
      chmod +x "$MOCK_BIN/$3"
    fi ;;
  *) printf 'Unexpected brew operation: %s\n' "$*" >&2; exit 99 ;;
esac
EOF
cat > "$MOCK_BIN/code" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'code %s\n' "$*" >> "$MOCK_DATA/calls"
[[ "$1 $2" == '--profile Default' ]] || exit 99
case "$3" in
  --list-extensions) cat "$MOCK_DATA/extensions" ;;
  --install-extension)
    printf '%s@1.0.0\n' "$4" >> "$MOCK_DATA/extensions"
    [[ "${MOCK_EXTENSION_FAIL:-0}" == 0 ]] || exit 9 ;;
  *) exit 99 ;;
esac
EOF
chmod +x "$MOCK_BIN/brew" "$MOCK_BIN/code" "$MOCK_BIN/claude"
fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
run() {
  env PATH="$MOCK_BIN:/usr/bin:/bin" NO_COLOR=1 \
    DAY_ONE_MAC_STATE_ROOT="$TEST_STATE" DAY_ONE_MAC_STATE_DIR="$TEST_STATE" \
    DAY_ONE_MAC_APPLICATION_CATALOG="$TEST_ROOT/apps.tsv" \
    "$SCRIPT_DIR/day-one-mac" "$@"
}
expect_failure() {
  local expected="$1" actual=0
  shift
  "$@" > "$TEST_ROOT/error" 2>&1 || actual=$?
  [[ "$actual" == "$expected" ]] || { cat "$TEST_ROOT/error" >&2; fail "expected $expected, got $actual"; }
}

run optional --module 10 --plan --clients claude,codex,copilot-vscode > "$TEST_ROOT/plan"
grep -Fq 'NOT checked or marked complete' "$TEST_ROOT/plan" || fail 'plan falsely implies authentication'
[[ ! -e "$TEST_STATE" && ! -e "$TEST_STATE.operation.lock" ]] || fail 'plan wrote setup state'
if grep -q 'install ' "$MOCK_DATA/calls"; then fail 'plan installed software'; fi
expect_failure 1 run optional --module 10 --check --clients codex
expect_failure 2 run optional --module 10 --plan --clients 'codex,unknown'
expect_failure 10 run optional --module 10 --apply --clients codex --yes
[[ ! -e "$TEST_STATE" ]] || fail 'blocked apply wrote state'
run advanced --module 16 --inventory > "$TEST_ROOT/inventory.tsv"
grep -Fxq $'app\tclaude-code' "$TEST_ROOT/inventory.tsv" || fail 'external app missing from inventory'
grep -Fxq $'formula\tgit' "$TEST_ROOT/inventory.tsv" || fail 'formula inventory missing'
grep -Fxq $'extension\texample.mixedcase' "$TEST_ROOT/inventory.tsv" || fail 'inventory extension ID was not normalised'
run advanced --module 16 --plan --manifest "$TEST_ROOT/inventory.tsv" > "$TEST_ROOT/inventory-plan"
[[ ! -e "$TEST_STATE" ]] || fail 'inventory wrote state'
run advanced --module 16 > "$TEST_ROOT/guide"
grep -Fq '# Advanced 16' "$TEST_ROOT/guide" || fail 'guide-only call changed meaning'

mkdir -p "$TEST_STATE/completed"
printf 'fixture\n' > "$TEST_STATE/completed/08"
expect_failure 10 run optional --module 10 --apply --clients claude,codex --yes
[[ ! -s "$MOCK_DATA/casks" ]] || fail '--yes chose Homebrew ownership'
MOCK_INSTALL_FAIL=codex expect_failure 7 run optional --module 10 --resume --yes --app-install-policy homebrew
grep -Fxq $'brew-dependency\tfixture-dependency' "$TEST_STATE/install-manifest.tsv" || fail 'failed cask dependency not recorded'
# A wizard edit must not silently change a previously approved resume selection.
printf 'raycast-ai\n' > "$TEST_STATE/ai-clients"
run optional --module 10 --resume --yes --app-install-policy homebrew > "$TEST_ROOT/resume"
grep -Fxq 'claude,codex' "$TEST_STATE/software-10-clients" || fail 'resume selection changed'
grep -Fxq $'brew-cask\tcodex' "$TEST_STATE/install-manifest.tsv" || fail 'new cask not owned'
if grep -q claude-code "$TEST_STATE/install-manifest.tsv"; then fail 'external client claimed'; fi
[[ ! -e "$MOCK_BIN/raycast" ]] || fail 'resume installed a newly selected wizard client'
run optional --module 10 --check > "$TEST_ROOT/check"
grep -Fq $'codex\tready\t1.2.3\thomebrew' "$TEST_ROOT/check" || fail 'owned client version not reported'
[[ ! -e "$TEST_STATE/advanced/completed/10" && ! -e "$TEST_STATE/optional-completed/ai-clients" ]] || fail 'AI guide marked complete'

printf 'formula\tgit\nformula\tbat\napp\tclaude-code\nextension\texample.existing\nextension\texample.new\n' > "$TEST_ROOT/selected.tsv"
run advanced --module 16 --plan --manifest "$TEST_ROOT/selected.tsv" > "$TEST_ROOT/software-plan"
grep -Fq 'Would run: brew install --formula bat' "$TEST_ROOT/software-plan" || fail 'formula command absent from preview'
grep -Fq 'Would run: code --profile Default --install-extension example.new' "$TEST_ROOT/software-plan" || fail 'extension command absent from preview'
MOCK_INSTALL_FAIL=bat expect_failure 7 run advanced --module 16 --apply --manifest "$TEST_ROOT/selected.tsv" --yes
cp "$TEST_STATE/software-16.tsv" "$TEST_ROOT/approved.tsv"
printf 'formula\tunapproved\n' > "$TEST_ROOT/selected.tsv"
run advanced --module 16 --resume --yes > "$TEST_ROOT/software-resume"
cmp "$TEST_ROOT/approved.tsv" "$TEST_STATE/software-16.tsv" || fail 'resume reread mutable input'
if grep -q unapproved "$MOCK_DATA/formulae"; then fail 'unapproved formula installed'; fi
grep -Fxq $'Default\texample.new' "$TEST_STATE/software-extension-installs.tsv" || fail 'new extension not recorded'
if grep -q example.existing "$TEST_STATE/software-extension-installs.tsv"; then fail 'preexisting extension claimed'; fi
before="$(grep -c 'install ' "$MOCK_DATA/calls")"
run advanced --module 16 --resume --yes > "$TEST_ROOT/repeated"
[[ "$before" == "$(grep -c 'install ' "$MOCK_DATA/calls")" ]] || fail 'repeat installed existing payloads'
[[ ! -e "$TEST_STATE/advanced/completed/16" ]] || fail 'payload install marked guide complete'
run advanced --module 16 --check > "$TEST_ROOT/software-check"

printf 'extension\texample.partial\n' > "$TEST_ROOT/extension.tsv"
MOCK_EXTENSION_FAIL=1 expect_failure 9 run advanced --module 16 --apply --manifest "$TEST_ROOT/extension.tsv" --yes
grep -Fxq $'Default\texample.partial' "$TEST_STATE/software-extension-installs.tsv" || fail 'partial extension not recorded'
run advanced --module 16 --resume --yes > "$TEST_ROOT/extension-resume"
run optional --status > "$TEST_ROOT/status"
grep -Eq 'partial +10 —' "$TEST_ROOT/status" || fail 'AI dashboard falsely claims readiness'
grep -Eq 'partial +16 —' "$TEST_ROOT/status" || fail 'software dashboard falsely completes guide'
run advanced --complete 16 --yes > "$TEST_ROOT/guide-complete"
run optional --status > "$TEST_ROOT/status-complete"
grep -Eq 'ready +16 —' "$TEST_ROOT/status-complete" || fail 'explicit manual completion was ignored'
MOCK_BREW_FAIL=1 run optional --status > "$TEST_ROOT/status-drift"
grep -Eq 'review +16 —' "$TEST_ROOT/status-drift" || fail 'manual fingerprint overrode failing live check'
printf 'old-guide\n' > "$TEST_STATE/advanced/completed/16"
run optional --status > "$TEST_ROOT/status-stale"
grep -Eq 'review +16 —' "$TEST_ROOT/status-stale" || fail 'stale manual fingerprint was ignored'

printf 'cask\tunknown-app\n' > "$TEST_ROOT/invalid.tsv"
expect_failure 2 run advanced --module 16 --plan --manifest "$TEST_ROOT/invalid.tsv"
printf 'formula\t--zap\n' > "$TEST_ROOT/invalid.tsv"
expect_failure 2 run advanced --module 16 --plan --manifest "$TEST_ROOT/invalid.tsv"
printf 'system("touch sentinel")\n' > "$TEST_ROOT/invalid.tsv"
expect_failure 2 run advanced --module 16 --apply --manifest "$TEST_ROOT/invalid.tsv" --yes
MOCK_BREW_FAIL=1 expect_failure 1 run advanced --module 16 --inventory
# Receipt without payload must block rather than duplicate the installation.
printf 'raycast\n' >> "$MOCK_DATA/casks"
expect_failure 1 run optional --module 10 --plan --clients raycast-ai
mkdir "$TEST_STATE.operation.lock"
printf '%s\n' "$$" > "$TEST_STATE.operation.lock/owner"
expect_failure 75 run advanced --module 16 --resume --yes
run advanced --module 16 --check > "$TEST_ROOT/locked-check"
rm "$TEST_STATE.operation.lock/owner"
rmdir "$TEST_STATE.operation.lock"
find "$TEST_STATE/module-runs" -name result -exec cat {} + > "$TEST_ROOT/results"
grep -Fxq incomplete "$TEST_ROOT/results" || fail 'failed runs lost'
grep -Fxq verified "$TEST_ROOT/results" || fail 'verified payload results missing'
printf 'PASS: AI and software plans, ownership, recovery, checks and guided boundaries\n'
