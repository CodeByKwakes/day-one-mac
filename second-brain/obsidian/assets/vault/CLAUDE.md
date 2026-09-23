# Second Brain instructions

## Scope

- This directory is an Obsidian vault containing Markdown knowledge, not a
  software repository.
- The three canonical domains are `development`, `software-content`, and
  `tech-content`. Shared source/system notes use `shared`.
- Source code stays outside this vault. Link to repositories; do not copy or
  generate dependency trees here.

## Safety and privacy

- Start with analysis and a proposed file list before editing.
- Do not read, summarize, move, or edit a note whose `ai_allowed` property is
  false or missing. Ask for explicit approval and name the affected path.
- Treat `sensitivity: work-confidential` as requiring explicit approval for
  this task even when `ai_allowed` is true.
- Never read or write `.obsidian`, `.git`, `.trash`, `80 Attachments`, secrets,
  credentials, private keys, tokens, or environment files.
- Never delete a note or attachment. Propose archive, merge, and duplicate
  actions for human review.
- Never add a remote, enable sync, install a plugin, or change application
  settings without an explicit request.

## Editing contract

- Preserve existing YAML properties and Markdown meaning.
- Use only the documented property values in `90 System/Knowledge System.md`.
- Do not edit files in `99 Templates`, `01 Dashboards`, or any `.base` file
  unless the request explicitly targets system configuration.
- Put new AI-generated proposals in `90 System/AI Review`. Do not silently
  merge them into canonical notes.
- Avoid broad vault-wide rewrites. Prefer small, reviewable batches.
- Never state that a link, command, example, or claim was verified unless it
  was actually checked.

## Knowledge quality

- Cite supporting vault notes with internal wikilinks and include their paths in
  the completion summary.
- Distinguish source-backed facts, the author's opinions, and your inference.
- Keep quotations short and link to the Source note.
- Prefer one canonical note per durable concept; propose links from other
  notes instead of copying the same explanation.
- Surface contradictions and missing evidence rather than smoothing them over.

## Completion

- List every file read when the scope is small.
- List every file created, moved, or changed.
- Report skipped restricted notes without summarizing their contents.
- Report unresolved questions and validation performed.
- If Git is present, suggest reviewing `git diff`; do not commit unless asked.
