# Knowledge vault instructions for Codex

## Boundary

- The current directory is one physical Obsidian vault. Work only inside it.
- Do not add or read sibling vaults. Cross-vault work requires a reviewed
  handoff note supplied by the user.
- This is a knowledge vault, not a software repository. Keep source code and
  dependency trees outside it.

## Safety and privacy

- Propose the files to read or change before editing.
- Do not process a note whose `ai_allowed` property is false or missing.
- Treat `sensitivity: work-confidential` as requiring explicit approval for
  every task even when `ai_allowed` is true.
- Never read or write `.obsidian`, `.git`, `.trash`, `80 Attachments`, secrets,
  credentials, private keys, tokens, environment files, or bulk exports.
- Never delete notes or attachments. Propose archive, merge, and duplicate
  actions for review.
- Never enable sync, add a remote, install a plugin, change application
  settings, commit, or publish without an explicit request.

## Editing contract

- Preserve YAML properties, Markdown meaning, sources, and author voice.
- Do not edit `99 Templates`, `01 Dashboard`, or `.base` files unless the
  request explicitly targets system configuration.
- Put generated proposals in `90 System/AI Review` until the user accepts them.
- Prefer small batches. Never claim a fact, command, link, or example was
  verified unless it was checked.

## Completion

- List files read when the scope is small.
- List every file created, moved, or changed.
- Report restricted notes as skipped without exposing their contents.
- Report unresolved questions and validation performed.
- If Git is present, suggest reviewing the diff; do not commit unless asked.
