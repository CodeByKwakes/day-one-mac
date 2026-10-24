#!/usr/bin/env bash
# Sourced by tools/validate.sh; run_fixture captures failures and diagnostics.

if "$SCRIPT_DIR/../tests/integration/test-release-installer.sh"; then
  pass "release archive and installer regressions pass"
else
  fail "release archive and installer regressions failed"
fi

run_fixture "documentation routes preserve canonical ownership and old section links" \
  "documentation route compatibility failed" \
  node "$SCRIPT_DIR/../tests/integration/test-documentation-routes.cjs" || true


run_fixture "audit remediation gates preserve current, credential-free evidence" \
  "audit remediation regression failed" \
  "$SCRIPT_DIR/../tests/integration/test-audit-remediation.sh" || true




run_fixture "HTTPS helpers and Git access gates preserve authentication boundaries" \
  "hosting authentication regression fixture failed" \
  "$SCRIPT_DIR/../tests/integration/test-hosting-auth.sh" || true

run_fixture "developer folders preserve existing layouts and make ghq optional" \
  "developer folder regressions failed" \
  /bin/bash "$SCRIPT_DIR/../tests/integration/test-developer-folders.sh" || true

run_fixture "offline documentation exports preserve navigation and privacy boundaries" \
  "offline documentation regressions failed" \
  "$SCRIPT_DIR/../tests/integration/test-docs.sh" || true

if command -v node >/dev/null 2>&1 && [[ -f "$SCRIPT_DIR/../tests/integration/test-vscode-profiles.cjs" ]]; then
  run_fixture "VS Code profile bundles preserve settings and explicit installation boundaries" \
    "VS Code profile script regressions failed" \
    node "$SCRIPT_DIR/../tests/integration/test-vscode-profiles.cjs" || true
fi

run_fixture "optional database installer is idempotent and diagnostic" \
  "optional database installer regression fixture failed" \
  "$SCRIPT_DIR/../tests/integration/test-configure-databases.sh" || true

run_fixture "optional module execution is preview-safe, resumable and locked" \
  "optional module execution fixture failed" \
  "$SCRIPT_DIR/../tests/integration/test-optional-module.sh" || true

run_fixture "AI clients and software selections preserve ownership and manual boundaries" \
  "AI client and software module fixture failed" \
  "$SCRIPT_DIR/../tests/integration/test-software-modules.sh" || true

run_fixture "profile/Warp artifacts and audit snapshots preserve manual boundaries" \
  "artifact module regression fixture failed" \
  "$SCRIPT_DIR/../tests/integration/test-artifact-modules.sh" || true

run_fixture "MCP snippets and AI governance preserve manual trust boundaries" \
  "AI artifact and governance fixture failed" \
  "$SCRIPT_DIR/../tests/integration/test-ai-artifacts.sh" || true

run_fixture "owned OmniRoute lifecycle refuses conflicts and resumes safely" \
  "OmniRoute module regression fixture failed" \
  "$SCRIPT_DIR/../tests/integration/test-omniroute-module.sh" || true

run_fixture "dotfile proposals and helper bundles preserve manual activation boundaries" \
  "configuration artifact fixture failed" \
  "$SCRIPT_DIR/../tests/integration/test-configuration-artifacts.sh" || true

run_fixture "scalar preferences preserve typed originals and refuse external drift" \
  "preference module fixture failed" \
  "$SCRIPT_DIR/../tests/integration/test-preference-module.sh" || true

run_fixture "identity reviews and checksum staging preserve manual and recovery boundaries" \
  "identity and restore module fixture failed" \
  "$SCRIPT_DIR/../tests/integration/test-review-and-restore.sh" || true

run_fixture "acceptance tooling preserves read-only plans and truthful release gates" \
  "acceptance tooling contract fixture failed" \
  "$SCRIPT_DIR/../tests/integration/test-acceptance-tooling.sh" || true

run_fixture "unified optional and advanced dashboard reports evidence safely" \
  "unified optional and advanced dashboard fixture failed" \
  "$SCRIPT_DIR/../tests/integration/test-optional-status.sh" || true

run_fixture "Homebrew, external, App Store, missing, and conflict application fixtures pass" \
  "application ownership and provenance regression fixture failed" \
  "$SCRIPT_DIR/../tests/integration/test-application-ownership.sh" || true


run_fixture "secret scan, SSH identity pairing, and validator dependency fixtures pass" \
  "secret scan, SSH identity pairing, or validator dependency fixture failed" \
  "$SCRIPT_DIR/../tests/integration/test-secret-scan-and-ssh.sh" || true


run_fixture "standalone runtime installs before Phase 1 and survives source removal" \
  "portable dispatcher installation or checkout resolution fixture failed" \
  "$SCRIPT_DIR/../tests/integration/test-portable-command.sh" || true

run_fixture "chezmoi preserves custom tools and uses VS Code only for human review" \
  "chezmoi VS Code diff and merge regression fixture failed" \
  "$SCRIPT_DIR/../tests/integration/test-chezmoi-vscode-tools.sh" || true

run_fixture "login and non-login shell PATH and the login-shell switch pass" \
  "shell PATH or login-shell switch fixture failed" \
  "$SCRIPT_DIR/../tests/integration/test-shell-environment.sh" || true

run_fixture "configuration choices preserve ownership and do not reinstall declined tools" \
  "configuration choice or preservation fixture failed" \
  "$SCRIPT_DIR/../tests/integration/test-configuration-choices.sh" || true

run_fixture "immutable projectless task creation, metadata, and boundaries pass" \
  "projectless workspace manager regression fixture failed" \
  "$SCRIPT_DIR/../tests/integration/test-workspace-manager.sh" || true

run_fixture "shortcut imports preserve preview and manual installation boundaries" \
  "shortcut import fixture failed" \
  "$SCRIPT_DIR/../tests/integration/test-shortcuts.sh" || true

run_fixture "track-aware Raycast commands and extension catalogue pass" \
  "Raycast command manager regression fixture failed" \
  "$SCRIPT_DIR/../tests/integration/test-raycast-manager.sh" || true

if "$PROJECT_DIR/extensions/second-brain/obsidian/scripts/validate.sh" >/dev/null; then
  pass "Obsidian Second Brain guides, assets, and setup fixture pass"
else
  fail "Obsidian Second Brain validation failed"
fi

if "$PROJECT_DIR/extensions/second-brain/notion/scripts/tests/test-notion-second-brain-manager.sh" >/dev/null; then
  pass "Notion Second Brain planner and generated helper fixture pass"
else
  fail "Notion Second Brain validation failed"
fi

run_fixture "profile configuration remains independent of guides" "profile configuration regression failed" node "$PROJECT_DIR/tests/integration/test-profile-config.cjs" || true
run_fixture "profile replacement previews and restores preserve existing user files" \
  "profile replacement regression failed" node "$PROJECT_DIR/tests/integration/test-vscode-profile-replacement.cjs" || true
run_fixture "phase dependencies isolate optional changes" "phase dependency regression failed" /bin/bash "$PROJECT_DIR/tests/integration/test-phase-dependencies.sh" || true

run_fixture "restructure safety regressions fail closed" \
  "restructure safety regression failed" \
  "$SCRIPT_DIR/../tests/integration/test-restructure-safety.sh" || true

run_fixture "retired setup commands are inert; tools work without phase markers" "AI/manual route contract failed" node "$PROJECT_DIR/tests/integration/test-ai-manual-contract.cjs" || true
run_fixture "assistant exports preserve scope, integrity and client separation" "assistant workspace contract failed" node "$PROJECT_DIR/tests/integration/test-assistant-workspace.cjs" || true
run_fixture "portable skills work independently with contained references" "portable skill package contract failed" node "$PROJECT_DIR/tests/integration/test-skills-package.cjs" || true
run_fixture "archive integrity, path safety and locks fail closed" "runtime safety regression failed" "$PROJECT_DIR/tests/integration/test-audit-regressions.sh" || true

run_fixture "retained scalar settings and recorded rollback preserve recovery" "retained operation regression failed" "$PROJECT_DIR/tests/integration/test-retained-operations.sh" || true
