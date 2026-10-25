# Use GitHub Copilot with an Obsidian vault

Use VS Code to inspect selected Markdown files and review proposed knowledge
changes. Obsidian remains the owner of the vault's layout and application settings.
Avoid editing the same note in both apps while reviewing changes.

## Prerequisites

Complete [vault setup](README.md) and [shared instructions](note-contract.md#shared-ai-instructions).
Use your approved Copilot account in the existing [VS Code setup](../../editors/vscode.md).
A client account or organizational policy can limit features independently of skill installation.

## 1. Open the intended folder

1. In VS Code, choose **File → Open Folder…** and select the intended vault.

   Expected: Explorer shows that vault, not every folder under your home directory.

2. Review workspace trust and the existing extensions before enabling AI tools.

   Expected: you understand the folder and active tool permissions. Opening a
   multi-root workspace does not make its code repositories read-only.

## 2. Verify instructions and the skill

1. Open Chat and select the Copilot harness available in your VS Code version.

   Expected: the account and chosen agent are visible. Other harnesses can use
   different instruction settings and permissions.

2. Choose **Open Customizations → Instructions** and verify `AGENTS.md`.

   Expected: the shared vault policy is discovered. Review conflicting existing
   instruction files rather than creating another copy of the same rules.

3. Under **Skills**, confirm `day-one-second-brain` or `day-one-mac` is available.

   Expected: the selected [skill installation](../../ai/day-one-skills.md#second-brain-specialist)
   is discoverable in this workspace. Project skills installed in a separate setup
   folder do not automatically follow you into the vault. Use that setup folder
   for the session, or deliberately install for this workspace or user scope.

Current Copilot supports `AGENTS.md` and `.agents/skills`. Check discovery in the
selected harness, rather than relying on an editor setting intended for another
harness. Sources checked 2026-10-25:
[custom instructions](https://code.visualstudio.com/docs/agent-customization/custom-instructions)
and [skills](https://code.visualstudio.com/docs/agent-customization/agent-skills).

## 3. Inspect without editing

1. Select Ask or Plan where available, and review the enabled tools and approval controls.

   Expected: the task is an inspection. Do not enable automatic command approval
   or broad filesystem access just to read a note.

2. Attach one harmless approved note and ask:

   ```text
   Read AGENTS.md and the attached note. Make no changes. Summarise its purpose,
   cite the supporting text, and list files read. Report files changed as none.
   ```

   Expected: the answer uses only the agreed evidence. Check the tool history and
   note contents; a mode name alone is not proof of read-only behavior.

3. For code context, follow [selected repository connections](../repositories.md).

   Expected: you attach selected files or reviewed extracts. Do not add an entire
   repository collection as context or run project scripts for a knowledge draft.

## 4. Review a proposed note

1. Request a draft in chat and check its citations.

   Expected: source-backed statements and inference are distinguishable.

2. Approve the exact destination under `90 System/AI Review` before saving it.

   Expected: source notes are preserved, and the changed-file list contains only
   the approved destination. Review the diff and reopen it in Obsidian.

3. Test a sample restore using [backup and recovery](backup.md).

   Expected: the restored sample is readable separately from the live vault.

## Troubleshooting

If a skill is missing, check its install scope and the active harness in Open
Customizations. If instructions are absent, inspect the session folder and the
request's instruction references. For access problems, review the actual
[VS Code security controls](https://code.visualstudio.com/docs/agents/run/security).
Do not widen permissions merely to make a missing file disappear from the report.
