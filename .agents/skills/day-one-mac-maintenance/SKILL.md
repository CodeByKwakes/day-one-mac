---
name: day-one-mac-maintenance
description: Maintain Day One Mac's AI-assisted and manual setup guides, bounded utilities, assistant assets and runtime packaging while preserving ownership and recovery contracts. Use for changes in this repository.
---

# Day One Mac maintenance

Read `AGENTS.md`, `docs/START-HERE.md` and the affected capability guide.
Normal setup has two routes: AI-assisted and manual. Both use canonical manual
recipes. The optional utility bundle performs bounded operations; never restore
whole-machine orchestration or require historical phase markers.

## Implementation contracts

- Target native Apple silicon and macOS Bash 3.2. Quote paths, preserve spaces
  and Unicode, and use helpers under `src/core/`. Do not source user profiles.
- Preserve state paths, ownership records and recovery data. Numeric module IDs
  are compatibility identifiers. Module 12 remains retired; use `vscode-profile`.
- Inspect actual prerequisites before mutation: platform, tools, selected inputs,
  ownership and required approval. Planning stays read-only. Use operation locks,
  private atomic writes and precisely scoped recovery.
- Keep executable metadata in `config/catalogs/` and `config/profiles/`. Guides
  explain it; generators must not parse prose as executable configuration.
- Package only allowlisted regular files. Exclude the retired runner, contributor
  skills, tests, dependency trees and personal data. Ship first-party assistant
  assets from `templates/skills/`, `templates/agents/` and `templates/setup-assistant/`.
- Export assistant workspaces to new private destinations. Keep shared skill
  content canonical and client-specific agent adapters separate. Client approval
  controls remain authoritative; instructions are not permission grants.
- Keep compatibility entry points inert or narrowly delegated. Resolve paths from
  the runtime root. Preserve published guide links with compatibility notices.
- Managed settings belong to IT. Do not assume administrator access or override
  organisation ownership, account controls or device policy.

## Documentation ownership

`docs/setup/ai/` owns bootstrap and assistant operation. `docs/setup/manual/`
owns runnable recipes. `docs/shared/` owns prerequisites, references, utilities,
verification and recovery. Retired assisted guides are compatibility notices.
Historical plans and audits remain in `maintainers/`; supersede rather than edit them.

Use the public `day-one-mac` command when documenting a utility. A manual recipe
must work without it. Normal setup must not depend on a permanent source checkout.
The approved outline remains authorization; routine edits need no repeated approval.

## Verification

Follow `CONTRIBUTING.md`: lint, static checks, integration tests and packaged
acceptance. Test a previous-version upgrade and rollback in an isolated home
before any authorized real-Mac installation. Verify assistant export integrity,
client file formats and relative references. Report fixture results separately
from live provider, hardware, account and managed-device acceptance.
