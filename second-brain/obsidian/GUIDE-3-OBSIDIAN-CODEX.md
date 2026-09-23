[← Project home](README.md) · **Guide 3** · [Dashboard →](DASHBOARD.md)

# Guide 3 — Obsidian + Codex

**Guide release:** 2.3.0.0 · **Time:** 70–100 minutes

## Outcome

You will have a structured Obsidian vault and a deliberately permissioned
Codex workflow for processing captured notes, finding connections, producing
review drafts, and reusing knowledge across development and content work.

Codex works with the vault's Markdown files directly. You do not need an
Obsidian AI plugin or an MCP server for this workflow.

## Step 1 — Decide what Codex may read 🔴

Codex can read files within the working directory you give it. The
`ai_allowed` property and `AGENTS.md` are instructions, not operating-system
access controls.

| Policy | Recommended design |
|---|---|
| All selected domains are approved for the selected OpenAI account | One `~/Vaults/Second Brain` vault; the three named domains elsewhere are the default example |
| Work notes must use a different account or must not be processed | Use [three physical vaults](THREE-VAULT-ARCHITECTURE.md), or keep work in a separate vault and never start Codex there |
| Employer policy permits only a managed service | Sign in with the approved account before opening the work vault |
| You are unsure | Set up Obsidian first and add Codex after approval |

Do not put passwords, tokens, private keys, customer exports, production data,
or authentication files in a knowledge vault.

🚦 Continue only when the signed-in account and the permitted note categories
are clear.

## Step 2 — Install Obsidian and Codex

Install Obsidian:

```bash
day-one-mac applications --id obsidian --install-missing
```

Choose exactly one Codex installation channel.

### Day One Mac Homebrew channel

```bash
day-one-mac applications --id codex --install-missing
day-one-mac applications --id codex
```

If Codex is missing, this asks whether to install the preferred Homebrew cask
or wait for another approved installer and recheck. If a valid
company-managed or standalone `codex` command already exists, Day One Mac
preserves it and records that external owner instead.

### OpenAI standalone channel

```bash
curl -fsSL https://chatgpt.com/codex/install.sh | sh
```

Do not install both. If `codex` already exists, preserve its current install
channel. Verify it:

```bash
codex --version
```

## Step 3 — Sign in deliberately

For browser-based sign-in:

```bash
codex login
codex login status
```

Select the ChatGPT workspace that is permitted to process the vault. To use an
API key instead, pass it through standard input rather than a command argument:

```bash
printenv OPENAI_API_KEY | codex login --with-api-key
codex login status
```

On a personal Mac, prefer macOS Keychain storage by adding this setting to the
existing `~/.codex/config.toml` rather than replacing that file:

```toml
cli_auth_credentials_store = "keyring"
```

If file-based credential storage is used, treat `~/.codex/auth.json` as a
secret. Never copy it into Obsidian, Git, a backup report, or a prompt.

## Step 4 — Create the vault

### Assisted path

Recommended dynamic wizard—select Codex only for vaults approved for the
signed-in OpenAI account:

```bash
./scripts/second-brain-manager.sh --guided --apply
```

Standard one-vault compatibility preset:

```bash
./scripts/setup-second-brain.sh --tools codex
./scripts/setup-second-brain.sh --tools codex --apply
```

Use `--tools raycast-codex` for Raycast plus Codex, or `--tools all` for
Raycast, Claude Code, and Codex.

### Manual path

```bash
mkdir -p "$HOME/Vaults/Second Brain"/{"00 Inbox","01 Dashboards"}
mkdir -p "$HOME/Vaults/Second Brain/10 Software Development"/{Projects,Learning,Reference}
mkdir -p "$HOME/Vaults/Second Brain/20 Software Content"/{Ideas,Drafts,Published}
mkdir -p "$HOME/Vaults/Second Brain/30 Tech Content"/{Ideas,Research,Scripts,Published}
mkdir -p "$HOME/Vaults/Second Brain"/{"40 Sources","50 People","80 Attachments","90 System/AI Review","90 System/Reviews","90 System/Reports","99 Templates"}
```

Copy the starter folders and `.gitignore` from `assets/vault/`, then copy
`AGENTS.md` to the vault root. For a Codex-only setup, skip `CLAUDE.md`. The
assisted setup updates only manager-marked generated files. It preserves an
unrecognised existing note and writes a proposed comparison beside it.

## Step 5 — Configure Obsidian

1. Open Obsidian and choose **Open folder as vault**.
2. Select `~/Vaults/Second Brain`.
3. In **Settings → Files and links**, set new notes to `00 Inbox` and
   attachments to `80 Attachments`.
4. Enable automatic internal-link updates.
5. Enable the Bases, Backlinks, Command palette, File recovery, Outgoing
   links, Properties view, Search, and Templates core plugins.
6. Set the Templates folder to `99 Templates`.
7. Open `01 Dashboards/Second Brain HQ.md` and verify the All Knowledge Base
   plus one Base for every domain selected in the manager.

Required community plugins: **none**.

## Step 6 — Understand the note contract

Every starter template uses the same essential properties:

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

Use one of `development`, `software-content`, `tech-content`, or `shared` for
`domain`. A missing or false `ai_allowed` value means Codex must not process
that note. This is a review cue; physical vault separation is the correct
control when policy requires isolation.

## Step 7 — Review vault-level `AGENTS.md`

Open `~/Vaults/Second Brain/AGENTS.md` before the first Codex session. It tells
Codex to:

- preserve frontmatter, wording, sources, and existing meaning;
- skip notes whose AI permission is false or unclear;
- stop before work-confidential processing without explicit approval;
- put generated proposals in `90 System/AI Review`;
- avoid `.obsidian`, `.git`, attachments, secrets, deletion, sync, remotes,
  publishing, and commits unless explicitly requested;
- report files read, files changed, and validation performed.

Keep the file at the vault root. Codex discovers `AGENTS.md` from the project
root/current working directory and applies more local instruction files when
present deeper in the tree.

## Step 8 — Start Codex with a bounded working directory

The assisted setup installs a manifest-aware launcher. If several vaults allow
Codex, it asks which one to open:

```bash
second-brain-codex
```

Its equivalent is:

```bash
codex --cd "$HOME/Vaults/Second Brain" \
  --sandbox workspace-write \
  --ask-for-approval on-request
```

Inside Codex, run `/status` and `/permissions`. Confirm the working directory
is exactly the intended vault and approval remains `on-request`. Use
`/permissions` whenever you need to change the active access level. Do not use
`danger-full-access` for routine knowledge work.

## Step 9 — Run a read-only smoke test 🚦

Start a separate read-only check:

```bash
codex --cd "$HOME/Vaults/Second Brain" \
  --sandbox read-only \
  --ask-for-approval on-request \
  "Read AGENTS.md and the selected domain index notes. Make no edits. Summarise the vault boundaries, then list files read and files changed. Files changed must be none."
```

Confirm that the summary is correct and no file changed. If Codex cites
information from outside the selected vault, stop and inspect the session's
working directory and permissions.

## Step 10 — Process the inbox in two passes

First request a proposal only:

```text
Read AGENTS.md, then review Markdown files in 00 Inbox. Do not edit or move
anything. Skip notes where ai_allowed is false or missing. For each remaining
item propose its destination, domain, type, status, up to three topics, and
links to existing notes. Flag duplicates and uncertain choices. Finish with
files read and files changed; files changed must be none.
```

After reviewing the table, apply only the accepted choices:

```text
Apply only the inbox changes I approved. Preserve content and frontmatter
fields. Do not overwrite or delete files. Put merge suggestions in
90 System/AI Review. Finish with every changed path and every item left in the
inbox.
```

Review the result in Obsidian. If the vault uses local Git history, use
`/review` or inspect `git diff` before accepting it.

## Step 11 — Synthesis workflows

### Development learning

```text
Read <note path> and its linked source notes. Create a proposal in
90 System/AI Review containing: an explanation in my own words, a practical
example, limitations, open questions, and supporting note links. Do not modify
the source note and label every inference.
```

### Software-content draft

```text
Using only approved development and source notes, propose a tutorial in
90 System/AI Review for <audience> to achieve <outcome>. Include prerequisites,
an outline, examples still requiring tests, source-note links, and a fact-check
list. Do not claim that commands ran unless you actually verified them.
```

### Tech-content angles

```text
Find approved notes relevant to <topic>. Propose three distinct audience
angles. For each, show the supporting note paths, separate facts from
inference, list likely counterarguments, and identify missing research. Do not
edit canonical notes.
```

## Step 12 — Weekly review and deterministic checks

Ask Codex for a read-only weekly review, then compare it with the local report:

```text
Do not change files. Report inbox items, active development work,
software-content drafts, tech-content drafts, notes modified this week,
metadata gaps, isolated notes, and the AI Review backlog. Suggest no more than
five next actions and cite paths.
```

```bash
second-brain-report
second-brain-report --write
```

The first command is read-only. The second intentionally writes a dated
aggregate report under `~/.local/state/second-brain/reports`.
Codex can explain the report but must not replace the underlying deterministic
check.

## Step 13 — Back up and validate

Use Time Machine or another versioned backup. Obsidian Sync is useful sync but
is not the independent backup. Validate the installed vault:

```bash
./scripts/validate.sh --vault "$HOME/Vaults/Second Brain"
```

## Completion gate 🚦

- [ ] Exactly one supported installation channel owns `codex`.
- [ ] `codex login status` shows the intended account.
- [ ] The vault is outside `~/Developer` and contains no secrets.
- [ ] `AGENTS.md` has been reviewed.
- [ ] `/status` and `/permissions` show the intended vault and access level.
- [ ] The read-only smoke test changes no files.
- [ ] Generated notes land in `90 System/AI Review` until accepted.
- [ ] A deterministic health report runs.
- [ ] An independent backup covers the vault.

Official references: [Codex CLI](https://learn.chatgpt.com/docs/codex/cli),
[authentication](https://learn.chatgpt.com/docs/auth),
[`AGENTS.md` configuration](https://learn.chatgpt.com/docs/agent-configuration/agents-md),
and [security and permissions](https://learn.chatgpt.com/docs/security).

---

[← Project home](README.md) · [Dashboard →](DASHBOARD.md)
