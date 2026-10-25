[← Project home](README.md) · **Guide 2** · [Dashboard →](dashboard.md)

# Guide 2 - Obsidian + Claude Code

**Time:** 75-110 minutes

## Outcome

You will have one structured Obsidian vault and a governed Claude Code
workflow for summarising notes, processing an inbox, finding connections, and
synthesising content across software development, software content, and tech
content.

Claude Code works directly with the vault's Markdown files. No Obsidian AI
plugin or MCP server is required.

## 1. Decide whether AI may see each domain 🔴

Claude Code receives access to the directory in which you launch it. A note
property is guidance for the agent, not an operating-system permission.

Use one of these designs:

| Policy | Design |
|---|---|
| All selected domains are approved for Claude | One `~/Vaults/Second Brain` vault; follow this guide as written. The three named domains elsewhere are the default example. |
| Work notes are not approved for Claude | Put work notes in a separate `~/Vaults/Work Brain`; never launch Claude there or add it with `--add-dir` |
| Work notes are approved only through an enterprise provider | Configure the organisation-approved Claude deployment before opening the vault |
| You are unsure | Start with Obsidian only; add Claude after approval |

Within an approved vault, still use `sensitivity` and `ai_allowed` so reviews
remain deliberate. Do not store passwords, tokens, private keys, customer
exports, or production data in the vault.

🚦 Continue only when you know which account pays for Claude Code and which
information that account is permitted to process.

## 2. Install Obsidian and Claude Code

<a id="optional-homebrew-installation"></a>
<a id="anthropic-native-channel"></a>

Use [AI client setup](../../ai/clients.md) to select one Claude Code installation
owner and sign in with the approved account. Install Obsidian through its existing
owner, or Homebrew when the app is absent and Homebrew is your chosen owner.

Expected result: Obsidian opens, `claude --version` and `claude doctor` succeed,
and the account can process the selected material. Account and billing availability
follow the current [Claude setup documentation](https://code.claude.com/docs/en/setup).

## 3. Prepare the existing vault

Complete the [manual vault task](README.md) first. Review the shared rules and create the client link as described in [note conventions](note-contract.md#shared-ai-instructions). If you already maintain shared `AGENTS.md`, use the [vault instruction and symlink task](note-contract.md#shared-ai-instructions) instead of copying rules.

Expected result: the vault contains test notes and reviewed instructions without duplicate competing policies.

## 4. Verify Obsidian before enabling AI

Open the [dashboard](dashboard.md) and verify a test note in the intended view. Confirm new notes go to `00 Inbox` and attachments go to `80 Attachments`.

Expected result: capture, search and navigation work without Claude.

## 5. Learn the shared property contract

Use the [shared note conventions](note-contract.md#note-properties). Preserve
existing properties and review permission metadata before processing a note body.

## 6. Review the vault-level `CLAUDE.md`

Open the shared policy through `CLAUDE.md` before the first session. Review these outcomes:

- Preserve YAML properties and existing meaning.
- Never edit `.obsidian`, templates, Base files, or attachments unless asked.
- Never delete notes; propose moves or merges first.
- Stop before processing notes marked `ai_allowed: false` or
  `sensitivity: work-confidential` without explicit approval.
- Put generated drafts in `90 System/AI Review` until the user accepts them.
- Link claims to source notes and distinguish facts from suggestions.
- Show changed files and validation before declaring completion.

Keep this file concise. Claude Code loads it at session start. Use `/context`
to confirm it appears under memory files. Use `/memory` to inspect or edit
memory deliberately.

## 7. Start Claude inside the vault in plan mode

Start the client directly in the selected vault:

```bash
cd "$HOME/Vaults/Second Brain"
claude --permission-mode plan
```

Then run:

```text
/context
/permissions
```

Confirm the working directory is the vault and `CLAUDE.md` is loaded. Plan
mode lets you inspect a proposed approach before granting write actions. Never
use `--dangerously-skip-permissions` for a knowledge vault.

## 8. Perform a read-only smoke test 🚦

Create three short real notes, one in each domain, and set `ai_allowed: true`
only if appropriate. Ask:

```text
Read the selected domain folders without editing anything. List the five most
useful connections between existing notes. For each connection, cite the note
paths that support it and label any inference. Finish with files read and
files changed; files changed must be none.
```

Check every cited note yourself. AI synthesis can be useful and still be
wrong. If Claude attempts an edit, deny it and review the project instruction.

## 9. Process the inbox safely

Use a two-stage workflow.

### Stage A - propose only

```text
Review Markdown files in 00 Inbox. Do not edit or move anything. For each
item, propose: destination folder, domain, type, status, up to three topics,
and links to existing notes. Skip anything with ai_allowed false or missing.
Return a concise table and flag duplicates or unclear items.
```

Correct the proposed classifications.

### Stage B - apply approved changes

```text
Apply only the inbox moves and property changes I approved. Preserve all
original content and frontmatter fields. Do not overwrite existing files or
delete duplicates; place merge suggestions in 90 System/AI Review. At the end,
list every changed path and any items left in the inbox.
```

Review the changes in Obsidian. If the vault is in Git, also run `git diff`.

## 10. Summarise a learning note

```text
Read "<note path>" and its linked source notes. Do not edit the source note.
Create a proposed synthesis in 90 System/AI Review using the Learning Note
shape: explanation in my own words, practical example, limitations, open
questions, and related wikilinks. Cite which vault notes support each claim.
```

Move the result into `10 Software Development/Learning` only after you have
verified it and removed unsupported claims.

## 11. Reuse knowledge for content

### Software-content draft

```text
Using only approved notes in 10 Software Development and 40 Sources, propose a
software tutorial in 90 System/AI Review. Audience: <audience>. Outcome:
<outcome>. Include prerequisites, a tested outline, examples that still need
verification, source-note links, and a fact-check checklist. Do not invent
commands or claim that code ran.
```

### Tech-content synthesis

```text
Find approved notes relevant to <topic> across all selected domains. Propose three
distinct audience angles. For each, show the supporting note links, what is
fact versus inference, likely counterarguments, and the missing research. Do
not edit canonical notes.
```

This cross-domain reuse is the main advantage of one vault: a development
lesson can become a tutorial and later a wider creator story without copying
three unrelated source files.

## 12. Add a controlled weekly review

Start in plan mode and ask:

```text
Prepare this week's review without changing files. Report: inbox items,
active development projects, software-content drafts, tech-content drafts,
notes modified this week, notes with missing domain/status/created properties,
and notes with no outbound wikilinks. Suggest at most five next actions.
```

Verify its result yourself:

Open the [dashboard](dashboard.md) and compare the proposed counts with its Inbox and AI Review views. Inspect a sample of the cited note paths. Investigate missing metadata or unresolved links before accepting the review; an AI summary alone is not a health check.

## 13. Back up and optionally add Git history

Follow [backup and recovery](backup.md), including its optional local Git history
section. Verify a restored sample before relying on the vault. Repository connections
do not enable a Git remote or synchronization.

## 14. Start capturing now

1. Use Capture template for three raw inputs.
2. Convert one into a Development Note.
3. Convert one into a Software Content note.
4. Convert one into a Tech Content note.
5. Create a Source note and link it to at least one content note.
6. Run the read-only connection smoke test.
7. Process only the approved notes.

Then follow the cadence in [Operating System](operations.md).

## Selected repository context

Follow [repository connections](../repositories.md) to select the checkout and
permitted files. Inspect the repository first without edits; then review a draft
before writing it into the vault. Do not treat a project link as approval to read
its entire repository. Do not run its build, tests or setup scripts for a note summary.

## Completion checklist

- [ ] Obsidian and exactly one Claude Code installation channel work.
- [ ] The configured vaults contain every selected domain and shared templates.
- [ ] Bases render in the central dashboard.
- [ ] `CLAUDE.md` is reviewed and appears in `/context`.
- [ ] `/permissions` was reviewed.
- [ ] The first session started in plan mode.
- [ ] A read-only synthesis cited real note paths and changed nothing.
- [ ] AI-restricted work material is physically separated when policy needs it.
- [ ] AI-generated drafts remain in `90 System/AI Review` until reviewed.
- [ ] An independent backup covers the vault.
- [ ] Real notes exist in every selected domain.

Official references: [Claude Code setup](https://code.claude.com/docs/en/setup),
[Claude Code memory and CLAUDE.md](https://code.claude.com/docs/en/memory),
[Claude Code CLI and permission modes](https://code.claude.com/docs/en/cli-reference),
[Obsidian Templates](https://obsidian.md/help/plugins/templates), and
[Obsidian Properties](https://obsidian.md/help/properties).

---

[← Project home](README.md) · [Dashboard and analytics →](dashboard.md)
