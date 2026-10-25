[← Project home](README.md) · **Guide 3** · [Dashboard →](dashboard.md)

# Guide 3 - Obsidian + Codex

**Time:** 70-100 minutes

## Outcome

You will have a structured Obsidian vault and a deliberately permissioned
Codex workflow for processing captured notes, finding connections, producing
review drafts, and reusing knowledge across development and content work.

Codex works with the vault's Markdown files directly. You do not need an
Obsidian AI plugin or an MCP server for this workflow.

## 1. Decide what Codex may read 🔴

Codex can read files within the working directory you give it. The
`ai_allowed` property and `AGENTS.md` are instructions, not operating-system
access controls.

| Policy | Recommended design |
|---|---|
| All selected domains are approved for the selected OpenAI account | One `~/Vaults/Second Brain` vault; the three named domains elsewhere are the default example |
| Work notes must use a different account or must not be processed | Use [three physical vaults](layouts.md), or keep work in a separate vault and never start Codex there |
| Employer policy permits only a managed service | Sign in with the approved account before opening the work vault |
| You are unsure | Set up Obsidian first and add Codex after approval |

Do not put passwords, tokens, private keys, customer exports, production data,
or authentication files in a knowledge vault.

🚦 Continue only when the signed-in account and the permitted note categories
are clear.

## 2. Install and verify the selected clients

Follow [AI client setup](../../ai/clients.md) for a single approved Codex installation channel. Install Obsidian using its existing owner, or `brew install --cask obsidian` if Homebrew is the selected owner and the app is absent.

Expected result: Obsidian opens and `codex --version` succeeds. Reuse an existing managed installation rather than adding a second owner.

## 3. Sign in deliberately

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

## 4. Prepare the existing vault

Complete the [manual vault task](README.md) first. Create or merge `AGENTS.md` using [shared instructions](note-contract.md#shared-ai-instructions). Do not overwrite an existing instruction file: merge the relevant rules and review the diff.

Expected result: the vault contains a test note, the selected domain folders and an instruction file you have read.

## 5. Verify Obsidian before enabling AI

Open the [dashboard](dashboard.md) and verify that your test note appears in the expected view. Confirm new notes go to `00 Inbox` and attachments go to `80 Attachments`.

Expected result: capture, search and navigation work without the AI client.

## 6. Understand the note contract

Use the [shared note conventions](note-contract.md#note-properties). Preserve
existing properties and review permission metadata before processing a note body.

## 7. Review vault-level `AGENTS.md`

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

## 8. Start Codex with a bounded working directory

Start the client directly in the intended vault:

```bash
codex --cd "$HOME/Vaults/Second Brain" \
  --sandbox workspace-write \
  --ask-for-approval on-request
```

Inside Codex, run `/status` and `/permissions`. Confirm the working directory
is exactly the intended vault and approval remains `on-request`. Use
`/permissions` whenever you need to change the active access level. Do not use
`danger-full-access` for routine knowledge work.

## 9. Run a read-only smoke test 🚦

Start a separate read-only check:

```bash
codex --cd "$HOME/Vaults/Second Brain" \
  --sandbox read-only \
  --ask-for-approval on-request \
  "Read AGENTS.md and the selected domain index notes. Make no edits. Summarise the vault boundaries, then list files read and files changed. Files changed must be none."
```

Confirm that the summary is correct and no file changed. Working-directory selection does not itself restrict all reads. If Codex cites
information outside the approved scope, stop and inspect the actual permissions.

## 10. Process the inbox in two passes

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

## 11. Synthesis workflows

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

## 12. Weekly review and deterministic checks

Ask Codex for a read-only weekly review, then compare it with your dashboard:

```text
Do not change files. Report inbox items, active development work,
software-content drafts, tech-content drafts, notes modified this week,
metadata gaps, isolated notes, and the AI Review backlog. Suggest no more than
five next actions and cite paths.
```

Open the [dashboard](dashboard.md) and compare the proposed counts with its Inbox and AI Review views. Inspect a sample of the cited note paths. Investigate missing metadata or unresolved links before accepting the review; an AI summary alone is not a health check.

## 13. Back up and validate

Follow [backup and recovery](backup.md). Verify that a restored harmless sample
opens separately and matches its selected backup version.

## Selected repository context

Follow [repository connections](../repositories.md) to select the checkout and
permitted files. Inspect the repository first without edits; then review a draft
before writing it into the vault. Do not treat a project link as approval to read
its entire repository. Do not run its build, tests or setup scripts for a note summary.

## Completion gate 🚦

- [ ] Exactly one supported installation channel owns `codex`.
- [ ] `codex login status` shows the intended account.
- [ ] The vault is outside `~/Developer` and contains no secrets.
- [ ] `AGENTS.md` has been reviewed.
- [ ] `/status` and `/permissions` show the intended vault and access level.
- [ ] The read-only smoke test changes no files.
- [ ] Generated notes land in `90 System/AI Review` until accepted.
- [ ] Dashboard views and a sample of cited note paths have been checked.
- [ ] An independent backup covers the vault.

Official references: [Codex CLI](https://learn.chatgpt.com/docs/codex/cli),
[authentication](https://learn.chatgpt.com/docs/auth),
[`AGENTS.md` configuration](https://learn.chatgpt.com/docs/agent-configuration/agents-md),
and [security and permissions](https://learn.chatgpt.com/docs/agent-approvals-security).

---

[← Project home](README.md) · [Dashboard →](dashboard.md)
