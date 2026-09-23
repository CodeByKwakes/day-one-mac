[← Alternatives](ALTERNATIVE-STACKS.md) · **Checklist** · [Project home →](README.md)

# Second Brain — Day One Mac checklist

## Shared foundation

- [ ] The vault location is outside `~/Developer`.
- [ ] Work confidentiality, AI processing, sync, and backup decisions are
      recorded.
- [ ] Obsidian opens `~/Vaults/Second Brain` or the deliberately chosen path.
- [ ] Every selected domain folder tree exists.
- [ ] New notes default to `00 Inbox`.
- [ ] Attachments default to `80 Attachments`.
- [ ] Templates points to `99 Templates`.
- [ ] Bases is enabled; the All Knowledge Base and one Base for every selected
      domain render.
- [ ] One real note exists in each domain.
- [ ] Properties use the documented vocabulary.
- [ ] An independent backup covers the vault.

## Guide 1 — Raycast

- [ ] Raycast 2.3.x or later opens normally.
- [ ] The Obsidian Store extension is installed and points to the right vault.
- [ ] Content search is enabled.
- [ ] Create Note defaults to `00 Inbox`.
- [ ] Search finds a unique phrase from a note body.
- [ ] Dashboard and capture commands target the correct vault.
- [ ] Aliases/hotkeys do not conflict with macOS or editor shortcuts.
- [ ] Raycast has only the macOS permissions the selected commands need.

## Guide 2 — Claude Code

- [ ] Exactly one installation channel owns `claude`.
- [ ] `claude --version` and `claude doctor` pass.
- [ ] The active account/provider is approved for the vault contents.
- [ ] Vault `CLAUDE.md` has been read and appears in `/context`.
- [ ] `/permissions` has been reviewed.
- [ ] The first vault session starts in plan mode.
- [ ] A read-only synthesis cites note paths and changes no files.
- [ ] Restricted work notes are physically separate when policy requires it.
- [ ] Generated proposals stay in `90 System/AI Review` until accepted.

## Guide 3 — Codex

- [ ] Exactly one installation channel owns `codex`.
- [ ] `codex login status` shows the intended account or workspace.
- [ ] Vault `AGENTS.md` has been read.
- [ ] `/status` shows the intended vault as the working directory.
- [ ] `/permissions` shows an appropriate sandbox and `on-request` approval.
- [ ] The first smoke test uses the read-only sandbox and changes no files.
- [ ] Restricted work notes are physically separate when policy requires it.
- [ ] Generated proposals stay in `90 System/AI Review` until accepted.

## Separate physical vaults

- [ ] Physical separation is required by an account, sync, or information policy.
- [ ] Every selected vault opens independently in Obsidian.
- [ ] Each vault has its own Inbox, Attachments, Templates, Bases, and backup settings.
- [ ] Raycast asks which vault to open, search, or capture into.
- [ ] Codex and Claude launchers expose only the selected vault.
- [ ] Cross-vault handoffs name the source vault, source note, and review date.
- [ ] `second-brain-report` reports every configured vault without changing one.
- [ ] `second-brain-manager.sh --validate` confirms the manifest and generated layout.
- [ ] A harmless restore test has passed for every configured vault backup.

## Dashboard and operations

- [ ] Second Brain HQ is bookmarked and easy to open.
- [ ] Domain views show the expected notes.
- [ ] Content pipelines use the shared status vocabulary.
- [ ] `second-brain-report` runs read-only across every configured vault.
- [ ] Weekly reports are written only intentionally.
- [ ] Inbox and AI Review are processed weekly.
- [ ] Backup restoration has been tested with a non-sensitive note.
- [ ] The system has been used for two weeks before adding more plugins.

## Final gate 🚦

You are ready when capture takes seconds, search returns the correct note,
dashboard results match the folders, and either Raycast retrieval, Claude's
reviewed synthesis, or Codex's reviewed synthesis works end to end. For
separate physical vaults, the same gate applies independently to each. An empty but
heavily customised vault is not complete.

---

[← Project home](README.md)
