[← Dashboard](DASHBOARD.md) · **Working loop** · [Alternatives →](ALTERNATIVE-STACKS.md)

# The operating system: capture, process, connect, create

Tools do not make a second brain; a small repeated loop does. Use this routine
for two weeks before changing the folder structure or installing more plugins.

The folder examples below describe the recommended single vault. With
[three physical vaults](THREE-VAULT-ARCHITECTURE.md), run the same loop inside
each selected vault and use `second-brain-report` for the combined health
summary.

## The four-step loop

```text
Capture quickly → Process deliberately → Connect selectively → Create something
```

## Daily — five minutes

### Capture

- Capture without classifying when interruption cost is high.
- Use Raycast Capture, Obsidian Create Note, or `Quick capture.md`.
- Record the source URL immediately when a claim came from somewhere else.
- Never paste a secret or customer dataset into a capture note.

### Finish one useful connection

Open one captured note and add:

- A clear title.
- Its domain, type, status, sensitivity, and AI decision.
- One sentence in your own words.
- One useful `[[wikilink]]`, if a real relationship exists.

Do not link every noun. Links should help retrieval, reasoning, or reuse.

## Weekly — 30 minutes

1. Open `00 Inbox` and `Quick capture.md`.
2. Delete low-value fragments.
3. Move every useful item to one canonical domain folder.
4. Apply a template if the note needs structure.
5. Review active development work and park stale items.
6. Review both content pipelines; choose one item to finish next.
7. Verify sources for anything nearing publication.
8. Review `90 System/AI Review`; accept, revise, or archive each proposal.
9. Run `second-brain-report --write`.
10. Create the Weekly Review note and record the next three outcomes.

The inbox may contain a running Quick Capture note after processing; its
unprocessed section should be empty.

## Monthly — 45 minutes

- Review the last four health reports for direction, not vanity metrics.
- Find duplicated notes and choose one canonical version.
- Review notes with no links and decide: connect, keep standalone, or archive.
- Review topic spelling and merge accidental variants.
- Test restore from backup with one non-sensitive note.
- Review Obsidian community plugins and remove any no longer used.
- Review Raycast Script Command access and the permissions of each selected AI client.
- Re-read `CLAUDE.md` and/or `AGENTS.md`; remove stale or contradictory rules.
- Confirm work-policy and sync decisions are still valid.

## Where a new item goes

Ask these questions in order:

1. Is it unprocessed? → `00 Inbox`.
2. Is it about building, debugging, or learning software? →
   `10 Software Development`.
3. Is it documentation or a tutorial closely tied to software? →
   `20 Software Content`.
4. Is it a broader video, newsletter, post, review, or creator project? →
   `30 Tech Content`.
5. Is it an external source useful to several notes? → `40 Sources`.
6. Is it complete and no longer active? → set `status: archived` and move it to
   an Archive subfolder only when the active views become noisy.

When software content could also be tech content, classify by its intended
output. An API tutorial belongs to Software Content; a video about how APIs
change developer careers belongs to Tech Content. Link them if they share
research.

## Status flow

Keep one vocabulary across both content domains:

```text
inbox → incubating → drafting → review → scheduled → published → archived
```

Development work normally uses:

```text
inbox → active → done → archived
```

Do not create new synonyms such as `started`, `doing`, and `in-progress`.
Dashboard filters depend on stable values.

## Source discipline

For a fact you may publish, a Source note should record:

- Canonical URL.
- Author or organisation.
- Published and accessed dates when relevant.
- Your summary rather than a full copied article.
- The exact claim this source supports.
- Limitations, bias, or expiry date.
- Links to the notes that use it.

AI output is not a source. It can locate or compare claims, but the source note
must point to material you can inspect.

## AI review discipline

- Ask for a proposal before asking for edits.
- Keep canonical notes unchanged until the proposal is reviewed.
- Require note-path citations for synthesis.
- Label inference and uncertainty.
- Never interpret “no objection” as permission to process restricted notes.
- Compare the changed-file list with the requested scope.
- Prefer several small sessions over a vault-wide rewrite.

## What success looks like after 14 days

- Capture takes under ten seconds.
- Search finds the note by title or remembered phrase.
- The inbox is processed weekly.
- At least one development note has fed a content note.
- At least one published or publishable item links back to inspected sources.
- Dashboard counts are trusted because properties are consistent.
- AI suggestions are reviewable and never silently replace your writing.
- Backup restoration has been tested.

If those outcomes fail, simplify the workflow before adding more tools.

---

[← Dashboard](DASHBOARD.md) · [Alternative stacks →](ALTERNATIVE-STACKS.md)
