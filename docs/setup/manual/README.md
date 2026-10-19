[← Documentation index](../../README.md)

# Manual Setup Handbook

**Audience:** beginners completing setup and maintainers reviewing its boundaries.
**Purpose:** one place to find human decisions, application steps, verification,
and recovery. This is not another mandatory checklist.

## Choose your route

- **Entirely manual setup:** use the [complete manual route](MANUAL-SETUP-GUIDE.md#manual-setup-flow).
  It does not require the Day One Mac runtime. Commands from individual tools
  are still used.
- **Manual steps after CLI preparation:** complete [required Phases 1–8](../assisted/README.md),
  select only needed extras, then use the chapters below. Do not repeat the
  fully manual bootstrap over an already configured Mac.
- **Choosing configuration ownership:** select [unmanaged files or chezmoi, shell, and prompt](../assisted/05-dotfiles-and-shell.md#choose-ownership-shell-and-prompt-first) independently.
- **Maintaining chezmoi-managed dotfiles:** start with the [chezmoi learning path](chezmoi.md).
- **Organising projects:** choose one of [four developer layouts and optional ghq](developer-folders.md), with a fully manual route or independent CLI assistance.
- **Building a knowledge system:** follow the [Second Brain walkthrough](second-brain.md)
  for Obsidian or Notion, integrations, daily use and recovery.
- **Accounts, keys and signing:** choose the [security learning path](security.md),
  then [1Password](1password.md) or [Apple Keychain](keychain-ssh.md).
- **Private npm packages:** use [Azure Artifacts npm authentication](azure-artifacts-npm.md)
  only if your project needs that feed. Setup, token renewal, and credential
  handling remain manual; Git/SSH authentication is separate.
- **Choosing software:** use the [application and formula catalogue](../../reference/SOFTWARE-CATALOGUE.md)
  for descriptions, selection rules, ownership and manual follow-up.

Existing detailed guides remain the canonical instructions, linked from this
handbook rather than copied into a second, competing procedure. Their old paths
still work. The handbook groups the manual work; module pages retain the exact
selection formats and execution details.

## What the CLI does and what you do

This table describes the current implementation. **Executable does not mean
fully automatic.** An `--apply` can install a payload, prepare review files, or
capture evidence; it does not necessarily activate a feature. Read the module
plan before applying it.

| Module | Current CLI responsibility | Your manual responsibility | Why it stays human-controlled |
|---|---|---|---|
| [09 · Databases](../../how-to/modules/optional/09-databases.md) | Create/resume selected development containers; inspect health | Choose services and engine/context; review versions, ports, credentials, startup and data needs; connect/import | Wrong context or data assumptions can affect the wrong environment |
| [10 · AI clients](../../how-to/modules/optional/10-ai-agents.md) | Install selected client payloads under the chosen app policy | Sign in, select subscriptions/providers, approve permissions | Installation is not authority to use an account or spend money |
| [10A · Gateway](../../how-to/modules/optional/10a-omniroute.md) | Manage an owned, digest-pinned local OrbStack container | Review resource/startup choices; configure providers, keys and routing | Resource use, secrets and request routing need deliberate consent |
| [11 · MCP](../../how-to/modules/optional/11-mcp-servers.md) | Generate selected workspace snippets | Inspect endpoints and permissions; authenticate and enable a server in each client | A valid snippet is not a trust decision |
| [VS Code profiles](../../how-to/apps/VSCODE-PROFILES.md) | Generate settings, extension and keybinding review files | Review extensions, choose profile and import in VS Code | Profile ownership and extension trust depend on your workflow |
| [13 · CLI tools](../../how-to/modules/optional/13-enhanced-cli-tools.md) | Install selected formulae and check presence | Choose tools; activate shell integration and update desired state if wanted | Installed commands should not silently alter every shell |
| [14 · Warp](../../how-to/modules/optional/14-warp-drive.md) | Export and verify a versioned bundle | Review/import in the intended account/workspace; test safely | An exported file does not prove successful application import |
| [15 · Dotfiles](../../how-to/modules/advanced/15-full-dotfiles-and-bootstrap.md) | Inventory selected files and prepare ownership proposals | Review secrets and templates; decide ownership; apply with chezmoi | A hash cannot establish that content is safe or portable |
| [16 · Software](../../how-to/modules/advanced/16-brewfile-apps-and-editor.md) | Install selected applications/formulae/extensions; current extension route targets Default | Choose app owner and editor profile; review extensions, Brewfile and MAS purchases | Do not install extensions into Default merely because it is available |
| [17 · Shell helpers](../../how-to/modules/advanced/17-shell-and-package-automation.md) | Prepare helper files and inspect package declarations | Review and activate helpers; test a new shell | Shell activation executes code in future sessions |
| [18 · Identities](../../how-to/modules/advanced/18-hosting-identities-azure-and-worktrees.md) | Inspect and propose identity/signing/worktree configuration | Select identity/provider; configure signing/routing; create worktrees | Metadata checks cannot prove account access or a real signature |
| [19 · macOS](../../how-to/modules/advanced/19-macos-gui-and-local-https.md) | Replay selected scalar preferences with recorded originals | Prefer System Settings/Finder/Dock UI; grant permissions, login items and certificate trust yourself | Ergonomics are personal; permission and trust prompts need context |
| [20 · Restore](../../how-to/modules/advanced/20-restore-and-migrate.md) | Stage explicitly listed, checksummed files privately | Inspect staged data; choose destination; perform live app/database imports | Checksums prove matching bytes, not a safe overwrite or usable database |
| [21 · Maintenance](../../how-to/modules/advanced/21-audit-maintenance-and-rebuild.md) | Capture bounded audit evidence and compare drift | Approve updates, cleanup and rebuilds; test backups | An audit finding is not permission to remove or upgrade anything |
| [22 · AI governance](../../how-to/modules/advanced/22-ai-skills-and-mcp-operations.md) | Inventory selected skills/MCP data and compare hashes | Review changed content, provenance and trust; approve a new baseline | Unchanged hashes do not certify trustworthy code |

For now, Module 16 can still install extensions into Default and Module 19 can
still write selected preferences. To follow the manual-first route, omit
extension rows from Module 16 and use the macOS UI instead of Module 19 apply.
Module 09 uses the active Docker context: verify it is the intended local
engine before applying. These cautions are not claims that new CLI safeguards
already exist.

## 1. macOS preferences and permissions

**When needed:** the baseline is working and you want different Finder, Dock,
keyboard, login-item, or local HTTPS behaviour.

**CLI preparation:** inspect the [settings catalogue](../assisted/MACOS-SETTINGS.md)
and [Module 19](../../how-to/modules/advanced/19-macos-gui-and-local-https.md). Selected scripted
preferences are optional replay, not required setup.

**Manual steps:** choose changes in the owning application or System Settings.
Grant accessibility, automation, login-item and certificate permissions only
to tools you intend to use. Do not approve a prompt just to clear a checklist.

**Verify:** reopen the relevant panel and test the behaviour in the actual app.
**Recover:** restore the previous UI value; if a script wrote it, use its
recorded originals and conflict guidance, not another wizard's rollback data.

## 2. AI accounts, providers and MCP trust

**When needed:** you deliberately selected AI clients or connections.
**CLI preparation:** install payloads or generate snippets in Modules 10/10A/11.
**Manual steps:** follow the [AI client guide](../../how-to/modules/optional/10-ai-agents.md),
[MCP guide](../../how-to/modules/optional/11-mcp-servers.md), and, only if chosen,
[gateway guide](../../how-to/modules/optional/10a-omniroute.md). Inspect the account, endpoint,
permissions and billing implications before enabling anything.

**Verify:** perform a small non-sensitive request or read-only tool call in the
selected client. **Recover:** disable the connection and revoke unwanted access
in the owning account; deleting a generated snippet does not revoke a token.

## 3. Editor profiles, extensions, Warp and app settings

**When needed:** work/personal contexts need separate application choices.
**CLI preparation:** `vscode-profile` prepares reviewed editor recipes; Module 14
exports Warp workflows. Module 16 can install selected payloads.
**Manual steps:** choose the target profile before installing extensions or
importing settings. Pick one owner: application sync, chezmoi, or a reviewed
manual export. Use [VS Code](../../how-to/apps/VSCODE.md),
[profiles](../../how-to/apps/VSCODE-PROFILES.md), [Warp](../../how-to/apps/WARP.md),
and [Raycast](../../how-to/apps/RAYCAST.md) for their actual application steps.

**Verify:** check the active profile/account and run one harmless workflow.
**Recover:** restore that profile's prior export/settings; avoid resetting every
profile or deleting unrelated extensions.

## 4. Chezmoi, ownership and shell activation

**When needed:** first-time dotfile setup, routine edits, or expansion beyond
the required baseline. Use the dedicated [chezmoi learning path](chezmoi.md)
for the tutorial, daily tasks, reference, templates/secrets and recovery.

**CLI preparation:** Phase 5 establishes the selected baseline. Module 15 only
proposes ownership; Module 17 prepares helper files.
**Manual steps:** review rendered changes, apply named targets, and activate
helpers only after reading them. **Verify:** syntax-check the rendered shell
content, then test a new shell. **Recover:** restore a reviewed source revision
and apply only affected targets; do not overwrite your entire home directory.

## 5. Git identities, signing, Azure and worktrees

**When needed:** another identity, provider or concurrent checkout is required.
**CLI preparation:** Module 18 inspects declarations and produces proposals.
**Manual steps:** follow [Module 18](../../how-to/modules/advanced/18-hosting-identities-azure-and-worktrees.md)
and the [worktree guide](../../how-to/development/worktrees/GIT-WORKTREES-VSCODE-AND-AI.md).
Choose the identity before writing provider defaults or repository rules.
**Verify:** inspect identity in the intended repository and verify an actual
test signature/authentication flow. **Recover:** revert the scoped configuration;
preserve uncommitted work before removing a checkout.

## 6. Database and gateway decisions

**When needed:** a project requires a local service, not merely because a module
exists. **CLI preparation:** review the [database](../../how-to/modules/optional/09-databases.md)
or [gateway](../../how-to/modules/optional/10a-omniroute.md) plan, context, image, memory, ports,
volumes and startup policy. **Manual steps:** approve those choices, then connect
with development-only credentials and import only reviewed test data.
**Verify:** use the intended client against the loopback service; health alone
does not prove your schema or routing. **Recover:** stop the selected service;
retain its volume until any data is backed up and deletion is approved.

## 7. Restore, maintenance and baseline acceptance

**When needed:** restoring selected data or investigating audit drift.
**CLI preparation:** Modules 20/21/22 stage files or collect evidence, not a
blanket permission to import, upgrade or trust.
**Manual steps:** review [restore](../../how-to/modules/advanced/20-restore-and-migrate.md),
[maintenance](../../how-to/modules/advanced/21-audit-maintenance-and-rebuild.md), or
[AI governance](../../how-to/modules/advanced/22-ai-skills-and-mcp-operations.md) instructions.
Current Module 22 `--resume` captures a fresh baseline from the saved selection:
do not use it just to make a drift failure disappear. Inspect the changes first.
**Verify:** open restored data in its owning app; review the new evidence against
the retained prior version. **Recover:** keep originals and prior baselines;
never use a successful checksum as permission to overwrite live data.

## Reading and keeping these guides

```bash
day-one-mac docs handbook --browser
day-one-mac docs chezmoi-guide --browser
day-one-mac docs second-brain-guide --browser
day-one-mac docs security --browser
day-one-mac docs software --browser
day-one-mac docs export --format html --output ./day-one-docs
day-one-mac docs export --format markdown --output ./day-one-markdown
```

The export directories must not already exist. Browser reading and printing
do not mark phases complete. See [offline documentation reference](../../reference/DOCUMENTATION-COMMANDS.md)
for export contents, version labels, privacy and cleanup.
