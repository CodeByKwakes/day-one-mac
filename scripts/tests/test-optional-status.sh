#!/usr/bin/env bash
set -euo pipefail
exec </dev/null

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEST_ROOT="$(mktemp -d /tmp/day-one-module-status-test.XXXXXX)"
trap 'rm -rf "$TEST_ROOT"' EXIT HUP INT TERM
TEST_HOME="$TEST_ROOT/home"
TEST_STATE="$TEST_HOME/.day-one-mac"
MOCK_BIN="$TEST_ROOT/bin"
mkdir -p "$TEST_STATE/advanced/completed" "$TEST_STATE/completed" "$MOCK_BIN"

printf 'databases,ai-clients,enhanced-cli,advanced\n' > "$TEST_STATE/optional-modules"
printf 'postgres\n' > "$TEST_STATE/database-services"
printf 'claude\n' > "$TEST_STATE/ai-clients"
printf 'brew-formula\tbat\n' > "$TEST_STATE/install-manifest.tsv"
printf 'complete\n' > "$TEST_STATE/completed/08"
shasum -a 256 "$PROJECT_DIR/docs/03-advanced/15-full-dotfiles-and-bootstrap.md" \
  | awk '{print $1}' > "$TEST_STATE/advanced/completed/15"

cat > "$MOCK_BIN/docker" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  --version|info) exit 0 ;;
  inspect)
    if [[ "$2" == *Config.Image* ]]; then
      printf 'postgres:17-alpine|127.0.0.1:5432|dev-pgdata:/var/lib/postgresql/data;|dev-net\n'
    else printf 'healthy\n'; fi ;;
  ps) printf 'dev-postgres\n' ;;
  *) exit 2 ;;
esac
EOF
cat > "$MOCK_BIN/brew" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-} ${2:-}" == 'list --formula' ]]; then printf 'bat\n'; exit 0; fi
exit 1
EOF
cat > "$MOCK_BIN/claude" <<'EOF'
#!/usr/bin/env bash
[[ "${1:-}" == --version ]] && printf 'fixture\n'
EOF
cat > "$MOCK_BIN/code" <<'EOF'
#!/usr/bin/env bash
case "${1:-}" in
  --list-profiles) printf 'Default\nWork\n' ;;
  --list-extensions) : ;;
esac
EOF
chmod +x "$MOCK_BIN/docker" "$MOCK_BIN/brew" "$MOCK_BIN/claude" "$MOCK_BIN/code"

run_status() {
  HOME="$TEST_HOME" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE" \
    DAY_ONE_MAC_APPLICATIONS_ROOT="$TEST_ROOT/no-applications" \
    DAY_ONE_MAC_APPLICATION_BREW_LOOKUP=disabled \
    PATH="$MOCK_BIN:/usr/bin:/bin:/usr/sbin:/sbin" \
    "$SCRIPT_DIR/optional-status.sh" "$@"
}

run_public_status() {
  HOME="$TEST_HOME" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE" \
    DAY_ONE_MAC_APPLICATIONS_ROOT="$TEST_ROOT/no-applications" \
    DAY_ONE_MAC_APPLICATION_BREW_LOOKUP=disabled \
    PATH="$MOCK_BIN:/usr/bin:/bin:/usr/sbin:/sbin" \
    "$SCRIPT_DIR/day-one-mac" optional --status "$@"
}

run_status > "$TEST_ROOT/status.txt"
run_status --details > "$TEST_ROOT/status-details.txt"
grep -Fq 'Next:' "$TEST_ROOT/status-details.txt"
[[ "$(wc -l < "$TEST_ROOT/status-details.txt")" -gt "$(wc -l < "$TEST_ROOT/status.txt")" ]]
# A healthy legacy container without recorded ownership must require review.
grep -Eq 'review +09 — Local databases' "$TEST_ROOT/status.txt"
grep -Fq 'database health or configuration verification failed' "$TEST_ROOT/status.txt"
grep -Eq 'partial +10 — AI clients' "$TEST_ROOT/status.txt"
grep -Eq 'not selected +10A — OmniRoute AI gateway' "$TEST_ROOT/status.txt"
grep -Eq 'ready +13 — Enhanced CLI tools' "$TEST_ROOT/status.txt"
grep -Eq 'ready +15 — Full dotfiles and bootstrap' "$TEST_ROOT/status.txt"
grep -Eq 'pending +16 — Brewfile, applications, and editor inventory' "$TEST_ROOT/status.txt"

grep -Fq 'Optional phase: partially complete' "$TEST_ROOT/status.txt"
grep -Fq 'Advanced phase: partially complete' "$TEST_ROOT/status.txt"
grep -Fq 'postgres: healthy' "$TEST_ROOT/status.txt"
grep -Fq 'redis: not selected / not verified' "$TEST_ROOT/status.txt"
grep -Fq 'claude: installed' "$TEST_ROOT/status.txt"
grep -Fq 'codex: not selected / not verified' "$TEST_ROOT/status.txt"
! grep -Fq 'fully complete' "$TEST_ROOT/status.txt"

printf 'bat,fd\n' > "$TEST_STATE/optional-cli-packages"
run_status > "$TEST_ROOT/cli-breakdown.txt"
grep -Fq 'bat: installed' "$TEST_ROOT/cli-breakdown.txt"
grep -Fq 'fd: not installed' "$TEST_ROOT/cli-breakdown.txt"
grep -Eq 'partial +13 — Enhanced CLI tools' "$TEST_ROOT/cli-breakdown.txt"
rm "$TEST_STATE/optional-cli-packages"

run_public_status > "$TEST_ROOT/public-status.txt"
grep -Eq 'review +09 — Local databases' "$TEST_ROOT/public-status.txt"
HOME="$TEST_HOME" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE" \
  DAY_ONE_MAC_APPLICATIONS_ROOT="$TEST_ROOT/no-applications" \
  DAY_ONE_MAC_APPLICATION_BREW_LOOKUP=disabled \
  PATH="$MOCK_BIN:/usr/bin:/bin:/usr/sbin:/sbin" \
  "$SCRIPT_DIR/day-one-mac" optional-status > "$TEST_ROOT/compatibility-status.txt"
grep -Eq 'review +09 — Local databases' "$TEST_ROOT/compatibility-status.txt"
HOME="$TEST_HOME" DAY_ONE_MAC_STATE_ROOT="$TEST_STATE" \
  DAY_ONE_MAC_APPLICATIONS_ROOT="$TEST_ROOT/no-applications" \
  DAY_ONE_MAC_APPLICATION_BREW_LOOKUP=disabled \
  PATH="$MOCK_BIN:/usr/bin:/bin:/usr/sbin:/sbin" \
  "$SCRIPT_DIR/day-one-mac" modules > "$TEST_ROOT/modules-status.txt"
grep -Eq 'review +09 — Local databases' "$TEST_ROOT/modules-status.txt"

if run_public_status --check >/dev/null 2>&1; then
  printf 'FAIL: --check accepted selected partial and pending modules\n' >&2
  exit 1
fi

if ! run_status --audit --report "$TEST_ROOT/module-audit.md" > "$TEST_ROOT/audit.txt" 2>&1; then
  printf 'FAIL: dashboard audit command failed\n' >&2
  sed -n '1,200p' "$TEST_ROOT/audit.txt" >&2
  exit 1
fi
[[ -s "$TEST_ROOT/module-audit.md" ]]
[[ -s "$TEST_ROOT/advanced-audit.md" ]]
[[ -s "$TEST_ROOT/repository-audit.tsv" ]]
grep -Fq '| 09 · Local databases | review |' "$TEST_ROOT/module-audit.md"
grep -Fq 'Status meanings' "$TEST_ROOT/module-audit.md"
grep -Fq "module audit: $TEST_ROOT/module-audit.md" "$TEST_ROOT/audit.txt"

if run_status --audit --check --report "$TEST_ROOT/strict-audit.md" >/dev/null 2>&1; then
  printf 'FAIL: combined module and environment audit accepted known failures\n' >&2
  exit 1
fi
[[ -s "$TEST_ROOT/strict-audit.md" ]]
[[ -s "$TEST_ROOT/advanced-audit.md" ]]

printf 'PASS: unified optional and advanced status and audit dashboard\n'
