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

- `domain`: `development`, `software-content`, `tech-content`, or `shared`.
- `type`: `capture`, `project`, `learning`, `content`, `source`, `person`,
  `review`, or `index`.
- `status`: `inbox`, `active`, `incubating`, `drafting`, `review`, `scheduled`,
  `published`, `done`, or `archived`.
- `created`: ISO date.
- `sensitivity`: `public`, `personal`, or `work-confidential`.
- `ai_allowed`: deliberate Boolean decision; not a security control.
- `topics`: short list of stable subjects.

## Rules

- Capture first; process weekly.
- Keep one canonical note and link to it.
- Source code stays in `~/Developer`.
- External claims link to Source notes.
- AI proposals stay in `90 System/AI Review` until reviewed.
- Sync is not backup.
