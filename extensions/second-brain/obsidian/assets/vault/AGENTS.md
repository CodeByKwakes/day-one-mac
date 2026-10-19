# Second Brain instructions for Codex

## Scope

- This directory is an Obsidian knowledge vault, not a software repository.
- Its canonical domains are `development`, `software-content`, and
  `tech-content`; shared source and system notes use `shared`.
- Source code stays outside this vault. Link to repositories instead of
  copying source trees or dependencies here.

## Safety and privacy

- Begin with analysis and a proposed file list before editing.
- Do not read, summarize, move, or edit a note whose `ai_allowed` property is
  false or missing. Name the affected path and request explicit approval.
- Treat `sensitivity: work-confidential` as requiring explicit approval for
  every task, even when `ai_allowed` is true.
- Do not read or write `.obsidian`, `.git`, `.trash`, `80 Attachments`, secrets,
  credentials, private keys, tokens, environment files, or bulk exports.
- Never delete a note or attachment. Propose archive, merge, and duplicate
  actions for human review.
- Never add a remote, enable sync, install a plugin, change application
  settings, commit, or publish without an explicit request.

## Editing contract

- Preserve existing YAML properties and Markdown meaning.
- Use only the property values documented in `90 System/Knowledge System.md`.
- Do not edit `99 Templates`, `01 Dashboards`, or `.base` files unless the task
  explicitly targets the knowledge-system configuration.
- Put new AI-generated proposals in `90 System/AI Review`; do not merge them
  silently into canonical notes.
- Prefer small, reviewable batches over vault-wide rewrites.
- Do not claim a link, command, example, or fact was verified unless it was
  actually checked.

## Knowledge quality

- Cite supporting vault notes with internal wikilinks and include their paths
  in the completion summary.
- Separate source-backed facts, the author's opinion, and your inference.
- Keep quotations short and link to the Source note.
- Prefer one canonical note per durable concept. Propose connections rather
  than copying the same explanation into several notes.
- Surface contradictions and missing evidence.

## Completion

- List files read when the scope is small.
- List every file created, moved, or changed.
- Report skipped restricted notes without revealing their contents.
- Report unresolved questions and validation performed.
- If Git is present, suggest reviewing the diff; do not commit unless asked.
