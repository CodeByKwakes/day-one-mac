[← Project home](README.md) · **Guide 2** · [Dashboard →](DASHBOARD.md)

# Guide 2 — Obsidian + Claude Code

**Guide release:** 2.3.0.0 · **Time:** 75–110 minutes

## Outcome

You will have one structured Obsidian vault and a governed Claude Code
workflow for summarising notes, processing an inbox, finding connections, and
synthesising content across software development, software content, and tech
content.

Claude Code works directly with the vault's Markdown files. No Obsidian AI
plugin or MCP server is required.

## Step 1 — Decide whether AI may see each domain 🔴

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

## Step 2 — Install Obsidian and Claude Code

Check Obsidian and choose Homebrew or another approved installer only when it
is missing:

```bash
day-one-mac applications --id obsidian --install-missing
```

Choose exactly one Claude Code installation channel.

### Ownership-aware stable channel

```bash
day-one-mac applications --id claude-code --install-missing
day-one-mac applications --id claude-code
```

If the ownership report says `Homebrew-managed`, upgrade it with:

```bash
brew upgrade --cask claude-code # only when the provenance report says Homebrew-managed
```

If the command is externally managed, leave upgrades to the company portal or
vendor installer shown in that report.

### Anthropic native channel

Anthropic currently recommends its native installer, which auto-updates:

```bash
curl -fsSL https://claude.ai/install.sh | bash -s stable
```

Do not install both channels. Do not use `sudo npm install -g`. Verify either
choice:

```bash
claude --version
claude doctor
```

Start Claude once, follow the supported browser login, and select the intended
Claude subscription, Console account, or organisation-managed provider:

```bash
claude
```

The free Claude.ai plan does not include Claude Code. Account availability and
billing may change, so confirm them in the current Anthropic documentation.

## Step 3 — Create the vault and folders

### Assisted path

Recommended dynamic wizard—select Claude Code only for vaults approved for its
account:

```bash
./scripts/second-brain-manager.sh --guided --apply
```

Standard one-vault compatibility preset:

```bash
./scripts/setup-second-brain.sh --tools claude
./scripts/setup-second-brain.sh --tools claude --apply
```

Both routes save the manifest used by the dynamic `second-brain-claude` vault
selector.

### Manual path

```bash
mkdir -p "$HOME/Vaults/Second Brain"/{"00 Inbox","01 Dashboards"}
mkdir -p "$HOME/Vaults/Second Brain/10 Software Development"/{Projects,Learning,Reference}
mkdir -p "$HOME/Vaults/Second Brain/20 Software Content"/{Ideas,Drafts,Published}
mkdir -p "$HOME/Vaults/Second Brain/30 Tech Content"/{Ideas,Research,Scripts,Published}
mkdir -p "$HOME/Vaults/Second Brain"/{"40 Sources","50 People","80 Attachments","90 System/AI Review","90 System/Reviews","90 System/Reports","99 Templates"}
```

Copy everything from `assets/vault/` into the vault, including `CLAUDE.md`.
The assisted path updates only manager-marked generated files. It preserves an
unrecognised pre-existing file and writes a proposed comparison beside it.

The folders mean:

- `00 Inbox`: capture first, classify later.
- `10 Software Development`: project notes, technical decisions, debugging,
  learning, and reusable reference; source code remains under `~/Developer`.
- `20 Software Content`: software documentation, tutorials, examples, and
  code-led articles through idea, draft, and published states.
- `30 Tech Content`: broader audience research, scripts, posts, newsletters,
  reviews, and published retrospectives.
- `40 Sources`: source notes with a URL, author, claim, and your summary.
- `90 System/AI Review`: AI-generated proposals that have not yet been merged
  into canonical notes.
- `99 Templates`: shared property vocabulary and note skeletons.

## Step 4 — Configure Obsidian

1. Open Obsidian and choose **Open folder as vault**.
2. Select `~/Vaults/Second Brain`.
3. In **Settings → Files and links**, set new notes to `00 Inbox` and
   attachments to `80 Attachments`.
4. Turn on automatic internal-link updates.
5. Enable the Bases, Backlinks, Command palette, File recovery, Outgoing links,
   Properties view, Search, and Templates core plugins.
6. Set the Templates folder to `99 Templates`.
7. Open `01 Dashboards/Second Brain HQ.md` and confirm its Base embeds render.

Required community plugins: **none**. Claude Code reads Markdown directly.
Dataview is optional for extra analytics, not for AI integration.

## Step 5 — Learn the shared property contract

Templates use these fields:

```yaml
domain: development
type: learning
status: active
created: 2026-09-12
sensitivity: personal
ai_allowed: true
topics:
  - example
```

Allowed domains are `development`, `software-content`, `tech-content`, and
`shared`. Use `ai_allowed: true` only after checking the contents and relevant
policy. Claude's project instructions tell it to stop on false or ambiguous
notes, but those instructions are not a technical access control.

Templates keep Claude's output predictable. They also let Obsidian Bases
filter and group notes without relying on folder names alone.

## Step 6 — Review the vault-level `CLAUDE.md`

Open `~/Vaults/Second Brain/CLAUDE.md` and read it before the first session. It
sets these rules:

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

## Step 7 — Start Claude inside the vault in plan mode

The assisted setup installs a launcher:

```bash
second-brain-claude
```

Its equivalent is:

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

## Step 8 — Perform a read-only smoke test 🚦

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

## Step 9 — Process the inbox safely

Use a two-stage workflow.

### Stage A — propose only

```text
Review Markdown files in 00 Inbox. Do not edit or move anything. For each
item, propose: destination folder, domain, type, status, up to three topics,
and links to existing notes. Skip anything with ai_allowed false or missing.
Return a concise table and flag duplicates or unclear items.
```

Correct the proposed classifications.

### Stage B — apply approved changes

```text
Apply only the inbox moves and property changes I approved. Preserve all
original content and frontmatter fields. Do not overwrite existing files or
delete duplicates; place merge suggestions in 90 System/AI Review. At the end,
list every changed path and any items left in the inbox.
```

Review the changes in Obsidian. If the vault is in Git, also run `git diff`.

## Step 10 — Summarise a learning note

```text
Read "<note path>" and its linked source notes. Do not edit the source note.
Create a proposed synthesis in 90 System/AI Review using the Learning Note
shape: explanation in my own words, practical example, limitations, open
questions, and related wikilinks. Cite which vault notes support each claim.
```

Move the result into `10 Software Development/Learning` only after you have
verified it and removed unsupported claims.

## Step 11 — Reuse knowledge for content

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

## Step 12 — Add a controlled weekly review

Start in plan mode and ask:

```text
Prepare this week's review without changing files. Report: inbox items,
active development projects, software-content drafts, tech-content drafts,
notes modified this week, notes with missing domain/status/created properties,
and notes with no outbound wikilinks. Suggest at most five next actions.
```

Compare its result with the deterministic local report:

```bash
second-brain-report
second-brain-report --write
```

The first prints only. The second writes a dated aggregate report under
`~/.local/state/second-brain/reports`. Claude should explain the
report, not silently replace the underlying checks.

If you intentionally used the manual, fixed single-vault path instead of the
manager, `./scripts/vault-health-report.sh --vault "$HOME/Vaults/Second Brain"`
remains available as the legacy per-vault report.

## Step 13 — Back up and optionally add Git history

Obsidian File Recovery is useful, but not a complete backup. Cover the vault
with Time Machine or another versioned backup. Obsidian Sync is a sync service,
not the independent backup.

Optional local Git history:

```bash
cd "$HOME/Vaults/Second Brain"
git init
git add .
git status
git commit -m "Initialize second brain"
```

Review `.gitignore` first. Keep any remote private and policy-approved. Do not
combine work-confidential notes with a personal remote. Git history is useful
for reviewing AI changes, but Git is not mandatory for Claude Code.

## Step 14 — Start capturing now

1. Use Capture template for three raw inputs.
2. Convert one into a Development Note.
3. Convert one into a Software Content note.
4. Convert one into a Tech Content note.
5. Create a Source note and link it to at least one content note.
6. Run the read-only connection smoke test.
7. Process only the approved notes.

Then follow the cadence in [Operating System](OPERATING-SYSTEM.md).

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

[← Project home](README.md) · [Dashboard and analytics →](DASHBOARD.md)
