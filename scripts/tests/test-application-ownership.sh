#!/usr/bin/env bash
# Deterministic fixtures for Homebrew, external, App Store, missing, and conflict states.
set -euo pipefail

# A fixture must never block on an interactive prompt: the runner asks for
# input when stdin is a TTY, which hangs when this is run from a real terminal
# rather than CI. Detach stdin so every child takes the non-interactive path.
exec </dev/null

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/day-one-application-test.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

export HOME="$TEST_ROOT/home"
export DAY_ONE_MAC_APPLICATIONS_ROOT="$TEST_ROOT/Applications"
export DAY_ONE_MAC_SYSTEM_FONTS_ROOT="$TEST_ROOT/Library/Fonts"
export DAY_ONE_MAC_USER_FONTS_ROOT="$HOME/Library/Fonts"
export DAY_ONE_MAC_APPLICATION_BREW_LOOKUP=disabled
mkdir -p "$HOME" "$DAY_ONE_MAC_APPLICATIONS_ROOT/Raycast.app/Contents" \
  "$DAY_ONE_MAC_APPLICATIONS_ROOT/Copilot.app/Contents" \
  "$DAY_ONE_MAC_APPLICATIONS_ROOT/Purge.app/Contents"

cat > "$DAY_ONE_MAC_APPLICATIONS_ROOT/Raycast.app/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>com.raycast.macos</string>
  <key>CFBundleShortVersionString</key><string>99.1-test</string>
</dict></plist>
EOF

cat > "$DAY_ONE_MAC_APPLICATIONS_ROOT/Purge.app/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>io.getpurge.app</string>
  <key>CFBundleShortVersionString</key><string>1.5.3-test</string>
</dict></plist>
EOF

cat > "$DAY_ONE_MAC_APPLICATIONS_ROOT/Copilot.app/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>com.github.copilot.test-fixture</string>
  <key>CFBundleShortVersionString</key><string>1.0-test</string>
</dict></plist>
EOF

source "$SCRIPT_DIR/lib/application-ownership.sh"

day_one_app_detect raycast
[[ "$DAY_ONE_APP_STATUS" == ready && "$DAY_ONE_APP_SOURCE" == external ]]
[[ "$DAY_ONE_APP_VERSION" == 99.1-test ]]

mkdir -p "$DAY_ONE_MAC_APPLICATIONS_ROOT/Raycast.app/Contents/_MASReceipt"
: > "$DAY_ONE_MAC_APPLICATIONS_ROOT/Raycast.app/Contents/_MASReceipt/receipt"
day_one_app_detect raycast
[[ "$DAY_ONE_APP_STATUS" == ready && "$DAY_ONE_APP_SOURCE" == app-store ]]

/usr/libexec/PlistBuddy -c 'Set :CFBundleIdentifier example.wrong-app' \
  "$DAY_ONE_MAC_APPLICATIONS_ROOT/Raycast.app/Contents/Info.plist"
day_one_app_detect raycast
[[ "$DAY_ONE_APP_STATUS" == review && "$DAY_ONE_APP_SOURCE" == review ]]
/usr/libexec/PlistBuddy -c 'Set :CFBundleIdentifier com.raycast.macos' \
  "$DAY_ONE_MAC_APPLICATIONS_ROOT/Raycast.app/Contents/Info.plist"

mkdir -p "$TEST_ROOT/bin"
cat > "$TEST_ROOT/bin/brew" <<'EOF'
#!/usr/bin/env bash
[[ "$1" == list && "$2" == --cask && "$3" == raycast ]]
EOF
cat > "$TEST_ROOT/bin/op" <<'EOF'
#!/usr/bin/env bash
printf 'test op\n'
EOF
chmod +x "$TEST_ROOT/bin/brew" "$TEST_ROOT/bin/op"
export PATH="$TEST_ROOT/bin:/usr/bin:/bin"
export DAY_ONE_MAC_APPLICATION_BREW_LOOKUP=enabled

day_one_app_detect raycast
[[ "$DAY_ONE_APP_STATUS" == ready && "$DAY_ONE_APP_SOURCE" == homebrew ]]
day_one_app_detect 1password-cli
[[ "$DAY_ONE_APP_STATUS" == ready && "$DAY_ONE_APP_SOURCE" == external ]]
day_one_app_detect warp
[[ "$DAY_ONE_APP_STATUS" == missing && "$DAY_ONE_APP_SOURCE" == missing ]]
day_one_app_detect purge
[[ "$DAY_ONE_APP_STATUS" == ready && "$DAY_ONE_APP_SOURCE" == external ]]
[[ "$DAY_ONE_APP_CASK" == jithin-sabu/tap/purge ]]
day_one_app_choose_install_route homebrew
[[ "$DAY_ONE_APP_INSTALL_CHOICE" == homebrew ]]
day_one_app_choose_install_route check-only
[[ "$DAY_ONE_APP_INSTALL_CHOICE" == stop ]]
day_one_app_choose_install_route prompt <<<"2" >/dev/null
[[ "$DAY_ONE_APP_INSTALL_CHOICE" == external ]]
day_one_app_prompt_external_action <<<'h' >/dev/null
[[ "$DAY_ONE_APP_EXTERNAL_ACTION" == homebrew ]]
day_one_app_prompt_external_action <<<'' >/dev/null
[[ "$DAY_ONE_APP_EXTERNAL_ACTION" == recheck ]]
day_one_app_detect copilot-app
[[ "$DAY_ONE_APP_STATUS" == ready && "$DAY_ONE_APP_SOURCE" == external ]]
[[ "$DAY_ONE_APP_FOUND_PATH" == "$DAY_ONE_MAC_APPLICATIONS_ROOT/Copilot.app" ]]

mv "$DAY_ONE_MAC_APPLICATIONS_ROOT/Copilot.app" \
  "$DAY_ONE_MAC_APPLICATIONS_ROOT/Copilot.app.not-installed"
day_one_app_detect copilot-app
[[ "$DAY_ONE_APP_STATUS" == missing && "$DAY_ONE_APP_SOURCE" == missing ]]
[[ "$DAY_ONE_APP_CASK" == github-copilot-app ]]

mkdir -p "$DAY_ONE_MAC_APPLICATIONS_ROOT/GitHub Copilot.app/Contents"
cp "$DAY_ONE_MAC_APPLICATIONS_ROOT/Copilot.app.not-installed/Contents/Info.plist" \
  "$DAY_ONE_MAC_APPLICATIONS_ROOT/GitHub Copilot.app/Contents/Info.plist"
cat > "$TEST_ROOT/bin/brew" <<'EOF'
#!/usr/bin/env bash
[[ "$1" == list && "$2" == --cask ]] \
  && [[ "$3" == raycast || "$3" == github-copilot-app || "$3" == jithin-sabu/tap/purge ]]
EOF
chmod +x "$TEST_ROOT/bin/brew"
day_one_app_detect copilot-app
[[ "$DAY_ONE_APP_STATUS" == ready && "$DAY_ONE_APP_SOURCE" == homebrew ]]
[[ "$DAY_ONE_APP_FOUND_PATH" == "$DAY_ONE_MAC_APPLICATIONS_ROOT/GitHub Copilot.app" ]]
day_one_app_detect purge
[[ "$DAY_ONE_APP_STATUS" == ready && "$DAY_ONE_APP_SOURCE" == homebrew ]]
[[ "$DAY_ONE_APP_VERSION" == 1.5.3-test ]]

REPORT_DIR="$TEST_ROOT/state"
mkdir -p "$REPORT_DIR"
printf 'brew-cask\traycast\n' > "$REPORT_DIR/install-manifest.tsv"
day_one_app_detect raycast
day_one_app_record_current "$REPORT_DIR/application-provenance.tsv" \
  "$REPORT_DIR/application-provenance.md" "$REPORT_DIR/install-manifest.tsv"
grep -Fq $'raycast\trequired\t04\tRaycast\tready\thomebrew' "$REPORT_DIR/application-provenance.tsv"
grep -Fq 'Installed by Day One Mac' "$REPORT_DIR/application-provenance.md"
grep -Fq '| Raycast | Yes | 04 | Ready | Homebrew-managed |' "$REPORT_DIR/application-provenance.md"
grep -Fq 'recorded Homebrew rollback' "$REPORT_DIR/application-provenance.md"

check_only_output="$TEST_ROOT/check-only.txt"
set +e
DAY_ONE_MAC_APPLICATION_CATALOG="$SCRIPT_DIR/tests/fixtures/application-catalog-missing.tsv" \
DAY_ONE_MAC_APPLICATION_COMMAND_LOOKUP=disabled \
DAY_ONE_MAC_APPLICATION_BREW_LOOKUP=disabled \
DAY_ONE_MAC_STATE_ROOT="$TEST_ROOT/check-only-state" \
  "$SCRIPT_DIR/application-status.sh" --id fixture-cli --install-missing \
  --app-install-policy check-only >"$check_only_output" 2>&1
check_only_rc=$?
set -e
[[ "$check_only_rc" -eq 10 ]]
grep -Fq 'Fixture CLI was not installed' "$check_only_output"
grep -Fq 'brew install --cask fixture-cli' "$check_only_output"

printf 'PASS: application ownership detection and provenance fixtures\n'
