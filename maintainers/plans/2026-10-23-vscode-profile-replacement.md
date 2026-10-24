# VS Code profile replacement implementation plan

> **For agentic workers:** Implement inline using the executing-plans workflow. The user requested this addition; do not apply it to their live profiles.

**Goal:** Add an explicit, preview-first settings/shortcuts replacement and restore workflow for Default and the three named recipes.

**Architecture:** Keep recipe generation unchanged. A separate replacement module consumes canonical recipes and explicitly selected VS Code User settings paths. Reuse core filesystem guards and operation locking; private backups record only the two files changed.

**Tech Stack:** Node.js 22+, macOS Bash 3.2, JSON/JSONC file bytes.

**Spec:** User request to override profiles, including Default; existing profile guide and preservation contracts in AGENTS.md.

## Global constraints

- Public interface: `day-one-mac vscode-profile`; Default, Full Stack, AI and Operations remain supported.
- Preview performs no writes, creates no locks and runs no VS Code commands.
- Replacement requires an exact preview approval hash and current Phase 8; restore must remain available when setup gates fail.
- Back up original bytes and absence before replacement. Restore refuses later edits and verifies backup integrity.
- Stable local VS Code only. Named targets are explicitly selected documented User resource paths; do not infer opaque profile IDs or edit internal databases.
- Preserve installed extensions, accounts, snippets, tasks, MCP and layout. User-managed shared resources and Settings Sync require manual review.
- No live installation, profile modification, release or commit is authorized by this implementation task.

## Review focus

1. Default versus named path confusion: disallow named recipes targeting Default and require an explicit named settings path.
2. Symlinks, traversal, nonregular files and alternate product roots: reject without writing or logging file contents.
3. Changes after preview: approval binds recipe and current file identities/digests; apply rechecks under the operation lock.
4. Partial replacement and later edits: retain a complete recovery record before writes; restore only originals or the recorded replacement bytes.
5. Invalid/changed backups, absent keybindings, non-ASCII paths and no-op reruns: verify hashes, preserve absence/modes and avoid unnecessary replacements.

## Task 1: Implement the bounded replacement transaction

**Files:** `src/modules/vscode-profiles/replace.cjs`, `build.cjs`, `tests/integration/test-vscode-profile-replacement.cjs`.

**Interfaces:** `replacement(root, data, options)` handles preview/apply/restore. Flags: `--replace-settings`, `--settings-file PATH`, `--restore BACKUP`, `--execute`, `--approve SHA256`; default generation remains unchanged.

- [x] Add fixture tests and observe failure before implementation.
- [x] Implement explicit path checks, snapshot approval, phase/lock gates, private recovery records, atomic file replacement and drift-safe restore.
- [x] Verify Default/named isolation, no-write previews, confirmation and gate failures, Unicode/spaces, symlink/nonregular rejection, exact JSONC recovery and partial-run recovery.

## Task 2: Integrate public documentation and packaging

**Files:** profile guide, command help/reference, runtime inventory, regression orchestration, packaged acceptance fixture.

- [x] Document manual versus script-assisted replacement, resource sharing, backups, restore and extension boundaries.
- [x] Register runtime helper and fixtures; test the command from an isolated installed archive.
- [x] Run lint, static validation, integration and packaged acceptance. Record actual outcomes and any limitations.

## Execution record

- Ruling: user-authorized implementation continues inline under the maintenance skill's existing-scope authorization; no live replacement is performed.
- Ruling: preserve unrelated extensions unless the pending optional scope clarification requests removal; this avoids expanding destructive scope by default.

- Scope confirmed by the user: replace settings/shortcuts and retain other installed extensions.
- RED→GREEN: the new fixture failed with unknown `--replace-settings` before implementation and passed afterward, including an injected second-file publication failure and exact recovery.
- Packaged acceptance exercised Default replacement and restoration in an isolated installed archive; no live profiles were changed.
- Verification: `pnpm run lint`, `pnpm run validate:static`, `pnpm run test:integration`, and `pnpm run acceptance:package` passed. Focused replacement tests additionally passed after the custom-shortcut restoration assertion was added.
- Source baseline: `00167b5` plus the preceding uncommitted terminal-history changes. No commit, public release, installed-runtime activation, live replacement, or managed-device acceptance was performed.
