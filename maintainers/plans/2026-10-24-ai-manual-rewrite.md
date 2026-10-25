# AI-assisted and manual setup implementation plan

> Approved on 24 October 2026 in the project conversation. Execute inline with
> the executing-plans skill. Review the whole branch independently before delivery.

**Goal:** Replace the scripted setup journey with AI-assisted and manual setup,
while retaining reviewed, individually selected utilities and recovery records.

**Architecture:** Manual recipes own installation and lifecycle instructions.
An exportable assistant workspace supplies shared skills and client-specific
roles. The optional `day-one-mac` command supplies bounded operations, never a
whole-machine runner. Existing state and ownership records keep their paths.

**Tech stack:** macOS Bash 3.2, Node.js 22+, Markdown, TSV, JSON and TOML.

**Spec:** The approved proposal in this conversation: two routes; an early
direct-provider or OmniRoute decision; six first-party skills; planner,
operator, verifier and maintainer roles; lifecycle documentation; independently
usable reviewed tools; isolated package migration and rollback validation.

## Global constraints

- Work on `codex/ai-manual-setup`, based on `4e776b4`.
- No live installation, credential changes, publication or push is authorized.
- Normal use needs no permanent source checkout. Manual setup needs no project scripts.
- Preserve private state, existing software, ownership and recovery records.
- Replace completion-marker gates with real operation prerequisites.
- Never erase disks, adopt foreign resources or silently replace client settings.
- Exported assistant workspaces are new private directories; updates use new exports.
- Client adapters inherit account and permission constraints. Skills are guidance,
  not permission enforcement. Do not promise equivalent client capabilities.
- Historical plans and audits remain historical. New decisions supersede them.

## Review focus

1. Old commands and integration shortcuts must not start the retired runner.
2. A fresh home without phase markers must support standalone reviewed tools.
3. An assistant export must work outside the checkout, with spaces and Unicode,
   and must refuse overwrites, unsafe links and incomplete verification.
4. Existing state must survive package activation and rollback byte-for-byte.
5. Ordinary guides and browser navigation must expose exactly two setup routes.

## Task 1: Retire orchestration and separate utility prerequisites

**Files:** `scripts/day-one-mac`, `src/cli/bootstrap-day-one-mac.sh`,
`src/core/module-execution.sh`, `src/modules/`, `config/catalogs/modules.tsv`,
`tests/integration/test-ai-manual-contract.cjs` and affected utility fixtures.

**Interfaces:** No arguments prints route help. Retired orchestration commands
exit 2 without mutation and name the migration guide. `tool --module ID` retains
the existing bounded selection interface; `optional` remains a compatibility
alias for explicit operations. Local apply checks platform and each tool's
actual dependencies. Existing operation locks and state locations remain.

- [x] Add and observe failing tests for retirement, read-only entry and missing-marker operation.
- [x] Replace public wizard dispatch and retire direct setup entry points.
- [x] Remove phase gates from retained utilities; keep dependency and ownership checks.
- [x] Adapt affected tests to verify real prerequisites and retained safety boundaries.
- [x] Run focused command, profile, gateway and utility tests.

## Task 2: Publish a portable assistant workspace

**Files:** `src/operations/assistant.sh`, `templates/skills/`,
`templates/agents/`, `templates/setup-assistant/`,
`tests/integration/test-assistant-workspace.cjs`.

**Interfaces:** `assistant --plan`, `assistant --export NEW_ABSOLUTE_DIRECTORY`,
and `assistant --check ABSOLUTE_DIRECTORY`. Export bundles guides, six skills,
four roles per client and integrity metadata. It never launches a client or
changes global configuration. Claude skills link to the shared project skills.

- [x] Add and observe failing export, collision, tamper and reference-resolution tests.
- [x] Implement private export and nonmutating integrity verification.
- [x] Create skills with clear triggers, lifecycle boundaries and canonical references.
- [x] Create current Codex, Claude and Copilot role adapters and instructions.
- [x] Run export tests and skill/schema checks.

## Task 3: Rewrite documentation and navigation

**Files:** `README.md`, `AGENTS.md`, `CONTRIBUTING.md`, `docs/START-HERE.md`,
`docs/README.md`, `docs/setup/ai/`, `docs/setup/manual/`, `docs/shared/`,
`src/docs/docs-browser.js`, `config/catalogs/document-aliases.json`, integrations.

**Interfaces:** AI guides own assistant operation; manual guides own tool recipes;
shared references own prerequisites, terminology and utility contracts. Retired
guide URLs preserve anchors and route to their current owner. The browser shows
AI-assisted and manual setup plus shared references, never a third setup route.

- [x] Rewrite entry points, AI bootstrap, client guides and operation/resumption.
- [x] Move retained utility procedures to shared reference; retire runner guides.
- [x] Document install/configure/update/remove/recover and adding a capability.
- [x] Update OmniRoute choice and bootstrap dependencies without requiring Phase 8.
- [x] Update browser navigation, integration commands, aliases and project instructions.
- [x] Run Markdown, local-link, command-example and browser fixtures.

## Task 4: Package and validate migration

**Files:** `config/runtime-files.txt`, runtime installer messages,
`tools/validation/`, `tests/integration/`, `maintainers/` release guidance.

**Interfaces:** Runtime excludes retired orchestration implementations. Recovery
and historical evidence are preserved. A new runtime can export an assistant
workspace after its source checkout is removed.

- [x] Replace retired-feature tests with retirement assertions; preserve tests for retained operations.
- [x] Run lint, static validation and integration regressions.
- [x] Test packaged operations and assistant export in isolated homes.
- [x] Test upgrade from the recorded baseline and rollback without state changes.
- [x] Perform independent whole-branch review, fix material findings and rerun affected checks.
- [x] Record evidence and remaining hardware/account acceptance limits.

Evidence and acceptance limits are recorded in the
[execution record](2026-10-24-ai-manual-progress.md).
