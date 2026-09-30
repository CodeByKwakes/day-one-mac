#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEST_ROOT="$(mktemp -d /tmp/day-one-mac-release-test.XXXXXX)"
trap 'rm -rf "$TEST_ROOT"' EXIT
fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }

"$SCRIPT_DIR/build-release.sh" "$TEST_ROOT/dist" >/dev/null
archive="$TEST_ROOT/dist/day-one-mac-runtime.tar.gz"
mkdir -p "$TEST_ROOT/temporary"
HOME="$TEST_ROOT/installed-home" TMPDIR="$TEST_ROOT/temporary" \
  "$PROJECT_ROOT/install-day-one-mac" --archive "$archive" >/dev/null
HOME="$TEST_ROOT/installed-home" "$TEST_ROOT/installed-home/.local/bin/day-one-mac" verify >/dev/null
HOME="$TEST_ROOT/installed-home" "$TEST_ROOT/installed-home/.local/bin/day-one-mac" \
  docs export --format html --output "$TEST_ROOT/export" >/dev/null
[[ -f "$TEST_ROOT/export/index.html" && -f "$TEST_ROOT/export/docs/manual/chezmoi.md" ]] \
  || fail 'installed release could not export its bundled handbook and chezmoi guides'
for topic in second-brain-guide folders security 1password keychain ssh software; do
  doc_path="$(HOME="$TEST_ROOT/installed-home" "$TEST_ROOT/installed-home/.local/bin/day-one-mac" docs "$topic")"
  [[ -f "$doc_path" ]] || fail "installed topic is missing: $topic"
done
for guide in second-brain security 1password keychain-ssh ssh-signing-and-recovery; do
  [[ -f "$TEST_ROOT/export/docs/manual/$guide.md" ]] || fail "export omitted handbook guide: $guide"
done
[[ -f "$TEST_ROOT/export/docs/20-reference/SOFTWARE-CATALOGUE.md" ]] || fail 'export omitted software catalogue'
HOME="$TEST_ROOT/installed-home" "$TEST_ROOT/installed-home/.local/bin/day-one-mac" verify >/dev/null
[[ -z "$(find "$TEST_ROOT/temporary" -mindepth 1 -print -quit)" ]] || fail 'installer leaked extraction directory'

# Exercise public Second Brain routes from an unrelated directory, using only
# packaged files and a disposable HOME. Preview must not save any user assets.
(
  export HOME="$TEST_ROOT/installed-home"
  export DAY_ONE_MAC_STATE_ROOT="$HOME/.day-one-mac"
  export SECOND_BRAIN_CONFIG_DIR="$HOME/.config/second-brain"
  export SECOND_BRAIN_STATE="$HOME/.local/state/second-brain"
  export SECOND_BRAIN_LAYOUT="$SECOND_BRAIN_CONFIG_DIR/layout.tsv"
  export SECOND_BRAIN_NOTION_CONFIG_DIR="$HOME/.config/second-brain-notion"
  export SECOND_BRAIN_NOTION_STATE_DIR="$HOME/.local/state/second-brain-notion"
  export SECOND_BRAIN_NOTION_RAYCAST_DIR="$HOME/.local/share/second-brain-notion/raycast"
  portable="$HOME/.local/bin/day-one-mac"
  cd "$TEST_ROOT/temporary"
  "$portable" second-brain > "$TEST_ROOT/second-brain-help"
  grep -Fq 'Usage: day-one-mac second-brain obsidian|notion' "$TEST_ROOT/second-brain-help" \
    || fail 'Second Brain selection help is missing'
  for manager in obsidian notion; do
    "$portable" second-brain "$manager" --help > "$TEST_ROOT/manager-help"
    grep -Fq "Usage: day-one-mac second-brain $manager" "$TEST_ROOT/manager-help" \
      || fail "packaged $manager route did not reach manager help"
    status=0
    "$portable" second-brain "$manager" --invalid-option > "$TEST_ROOT/manager-error" 2>&1 || status=$?
    [[ "$status" == 1 ]] || fail "$manager route lost its manager failure code"
    grep -Fq 'unknown option: --invalid-option' "$TEST_ROOT/manager-error" \
      || fail "$manager route lost the unknown argument"
  done
  status=0
  "$portable" second-brain unknown > "$TEST_ROOT/manager-error" 2>&1 || status=$?
  [[ "$status" == 2 ]] || fail 'unknown manager did not fail closed'
  "$portable" second-brain obsidian --preset unified --tools none \
    --single-vault "$HOME/Vaults/Review Notes" > "$TEST_ROOT/obsidian-preview"
  grep -Fq "$HOME/Vaults/Review Notes" "$TEST_ROOT/obsidian-preview" \
    || fail 'Obsidian route lost a path containing spaces'
  grep -Fq 'Preview only' "$TEST_ROOT/obsidian-preview" || fail 'Obsidian route did not preview'
  "$portable" second-brain notion --domains 'Review Notes,Team Learning' \
    --assistants none --raycast no > "$TEST_ROOT/notion-preview"
  grep -Fq 'Team Learning' "$TEST_ROOT/notion-preview" || fail 'Notion route lost its domains argument'
  grep -Fq 'preview only' "$TEST_ROOT/notion-preview" || fail 'Notion route did not preview'
  [[ ! -e "$HOME/Vaults" && ! -e "$SECOND_BRAIN_CONFIG_DIR" && ! -e "$SECOND_BRAIN_STATE" \
     && ! -e "$SECOND_BRAIN_NOTION_CONFIG_DIR" && ! -e "$SECOND_BRAIN_NOTION_STATE_DIR" \
     && ! -e "$SECOND_BRAIN_NOTION_RAYCAST_DIR" ]] || fail 'manager preview persisted user assets'
)

# Explicit archive must win over the checkout autodetection.
printf 'corrupted\n' >> "$archive"
if HOME="$TEST_ROOT/corrupt-home" "$PROJECT_ROOT/install-day-one-mac" --archive "$archive" >"$TEST_ROOT/result" 2>&1; then
  fail 'corrupt explicit archive was accepted or ignored'
fi
grep -Fq 'checksum verification failed' "$TEST_ROOT/result" || fail 'checksum failure was not explained'
[[ ! -e "$TEST_ROOT/corrupt-home/.local/bin/day-one-mac" ]] || fail 'corruption installed a launcher'

# Restore matching bytes/checksum, then reject provenance before extraction.
(cd "$TEST_ROOT/dist" && shasum -a 256 day-one-mac-runtime.tar.gz > day-one-mac-runtime.tar.gz.sha256)
mkdir -p "$TEST_ROOT/bin"
cat > "$TEST_ROOT/bin/gh" <<'FIXTURE'
#!/usr/bin/env bash
printf '%s\n' "$*" > "$TEST_GH_LOG"
exit 1
FIXTURE
chmod +x "$TEST_ROOT/bin/gh"
if HOME="$TEST_ROOT/untrusted-home" TEST_GH_LOG="$TEST_ROOT/gh.log" PATH="$TEST_ROOT/bin:$PATH" \
  "$PROJECT_ROOT/install-day-one-mac" --archive "$archive" --require-attestation >"$TEST_ROOT/result" 2>&1; then
  fail 'failed attestation was accepted'
fi
grep -Fq 'attestation verify' "$TEST_ROOT/gh.log" || fail 'attestation verifier was not invoked'
grep -Fq -- '--signer-workflow CodeByKwakes/day-one-mac/.github/workflows/release.yml' "$TEST_ROOT/gh.log" || fail 'signer workflow not constrained'
[[ ! -e "$TEST_ROOT/untrusted-home/.local/bin/day-one-mac" ]] || fail 'untrusted archive installed a launcher'
if "$PROJECT_ROOT/install-day-one-mac" --source "$PROJECT_ROOT" --require-attestation >/dev/null 2>&1; then
  fail 'source mode bypassed required attestation'
fi
printf 'PASS: offline release install, extraction cleanup, checksum rejection and fail-closed provenance\n'
