---
domain: shared
type: review
status: active
created: 2026-09-12
sensitivity: personal
ai_allowed: true
topics:
  - knowledge-management
---

# Knowledge System

## Properties

- `domain`: this vault's documented domain, or `shared` for system notes.
- `type`: `capture`, `project`, `learning`, `content`, `source`, `person`,
  `review`, or `index`.
- `status`: `inbox`, `active`, `incubating`, `drafting`, `review`, `scheduled`,
  `published`, `done`, or `archived`.
- `created`: ISO date.
- `sensitivity`: `public`, `personal`, or `work-confidential`.
- `ai_allowed`: deliberate Boolean review cue; not an access control.
- `topics`: short list of stable subjects.

## Rules

- Capture first; process weekly.
- Keep one canonical note and link to it.
- Link external claims to source notes.
- Keep AI proposals in `90 System/AI Review` until reviewed.
- Use a reviewed handoff rather than silently reading a sibling vault.
- Sync is not backup.
