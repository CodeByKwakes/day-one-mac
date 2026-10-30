---
name: day-one-mac-maintenance
description: Maintain Day One Mac's manual guides, portable AI skills, reviewed helpers and static reader while preserving ownership and recovery boundaries. Use for changes in this repository.
---

# Day One Mac maintenance

Read AGENTS.md, docs/START-HERE.md and the owning capability guide. AI-assisted
and manual setup share canonical manual recipes. There is no mandatory runtime, global setup command, setup wizard, background
manager or permanent checkout requirement. The separately installed optional
MCP server under `integrations/mcp` is a bounded tool transport, not a setup
route or machine manager.

## Implementation contracts

- Target native Apple silicon. Shell helpers use macOS Bash 3.2, quote paths and
  preserve spaces and Unicode. Do not source user profiles for inspection.
- Keep skill sources under `templates/skills/` and shared role policies under
  `templates/agents/shared/`. Generate native role adapters before installable
  packages under `skills/`. Keep contributor skills out of public packages.
- Review every addition to `config/skill-sources.txt` and
  `config/document-sources.txt`. Package regular public files only, never private
  notes, contributor skills, credentials or dependency trees.
- Helpers under `helpers/` must work inside independently installed skills with
  their bundled configuration. Do not depend on global manager state.
- Preview mutations, validate inputs and ownership, detect drift and preserve
  private recovery backups outside the installed skill. Keep existing backups.
- Manual guides must work without project helpers. Keep each recipe in its
  owning manual topic; AI guidance selects that recipe instead of duplicating it.
- Respect client permissions, managed-device ownership and account controls.
  A skill instruction is not permission to execute a destructive operation.
- Preserve old guide URLs using compatibility notices. Earlier plans, audits,
  tags and releases remain historical; supersede rather than rewrite them.

## Verification

Follow CONTRIBUTING.md: lint, static checks, integration fixtures and pinned
Skills CLI acceptance for packaging changes. Verify source-independent packages,
contained links, profile recovery and offline reader behaviour. Report fixture
results separately from live hardware, provider and account checks. Do not push,
publish or alter the live Mac without the user's corresponding authorization.
