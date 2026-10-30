# Configure VS Code for development

Set up personal profiles for Angular, NestJS, Prisma, Nx, TypeScript, databases
and AI work on macOS. This complete manual task keeps editor settings in
**User Settings for the active profile**; it does not create project `.vscode`
files or invoke Day One Mac scripts.

## Before you start

Complete [Homebrew](../homebrew.md), [language tools](../languages.md) and
[Zsh startup](../shell/zsh.md). Keep your approved existing VS Code installation;
install `visual-studio-code` through Homebrew only when absent and Homebrew is
its intended owner. Use the organisation's channel for managed software.

Have the selected project's dependencies, Git and Node.js available before
testing Full Stack or AI. Select JetBrainsMono Nerd Font if installed, or keep
the supplied fallback font. Warp is optional; omit its external-terminal setting
when you do not use it. Account access and managed extension policies remain
prerequisites for the AI tools you select.

Profiles organise settings and extensions. They do not isolate accounts, agent
credentials, database permissions or CLI configuration. **User Settings** means
the active profile's personal settings; workspace settings and IT policy can
override them. This procedure creates no project `.vscode` files.

The exact JSON is generated from the versioned configuration in
[profile data](../../../shared/reference/vscode-profile-data.md). Keep that page
open beside this procedure. It owns the copyable values; the tables below explain
where each group belongs. Marketplace links identify extensions; check the
publisher and the installed editor's setting schema before applying preferences.
The official [profile documentation](https://code.visualstudio.com/docs/configure/profiles)
and [AI overview](https://code.visualstudio.com/docs/agents/overview) were consulted
on 24 October 2026. Account, policy and version differences can affect availability.

## Open VS Code and enable the CLI

1. Open the approved VS Code application.

   Expected result: the editor opens without a conflicting duplicate installation.

2. Run **Shell Command: Install 'code' command in PATH** from the Command Palette
   (`Cmd+Shift+P`).

   Expected result: `code --version` prints the editor version in a new terminal.

3. [Export each existing profile](#export-a-portable-profile---preferred) that
   you intend to change.

   Expected result: a private `.code-profile` backup exists for each selected profile.

4. Review Settings Sync in the Manage gear menu and pause it while replacing an
   existing configuration, keeping the cloud copy.

   Expected result: changes on this Mac will not immediately replace another
   device's configuration. Re-enable Sync only after local verification.

## Complete the minimum setup

1. Open the intended repository and select Default or one task profile.
   Expected: the window shows the intended checkout and profile.
2. Follow [profile setup](vscode/profiles.md#1-choose-and-create-profiles).
   Configure Default before copying it into selected named profiles.
   Expected: only the profiles you need exist.
3. Install the [selected extensions](vscode/extensions.md#2-install-the-final-extension-lists).
   Expected: each required extension is enabled in its intended profile.
4. Apply [shared settings](vscode/profiles.md#3-apply-shared-user-settings), then
   the selected profile overrides. Merge values; do not replace unrelated settings.
   Expected: the active profile uses the reviewed formatter, terminal and UI choices.
5. Configure [editing and language behaviour](vscode/editing.md) only as needed.
   Expected: a disposable file demonstrates the selected shortcut and formatter.
6. Complete [verification and export](vscode/recovery.md#9-verify-and-export).
   Expected: a real project check and a private recoverable profile export exist.

## Task reference

| Task | Owner |
|---|---|
| Select extensions and understand their purpose | [Extensions](vscode/extensions.md) |
| Create profiles, merge settings and apply overrides | [Profiles and settings](vscode/profiles.md) |
| Imports, keyboard shortcuts, environment files and language display | [Editing](vscode/editing.md) |
| Verify, export, reset or recover Settings Sync | [Recovery](vscode/recovery.md) |
| Copy exact generated JSON | [Profile data](../../../shared/reference/vscode-profile-data.md) |

## Finish related development tasks

The editor setup above is complete without these optional integrations. Each
link below is a complete task with its own verification; choose only what you need.

| Task | Owner |
|---|---|
| Native worktree lifecycle and worked UI example | [VS Code worktrees](../development/worktrees/vscode.md) |
| Prompt generation, Copilot, Codex and Claude workflows | [AI workflows](../ai/workflows.md) |
| Project instructions, skill installation and Claude symlinks | [Instructions, agents and skills](../ai/instructions-agents-skills.md) |
| Project/global MCP servers | [MCP setup](../ai/mcp.md) |
| Prefix history, shell startup and Warp compatibility | [Zsh](../shell/zsh.md) |
| DataGrip and VS Code connections to the same databases | [Database clients](../databases/README.md) |

Use one editing agent per worktree. Database credentials belong in each client's
connection storage, not exported settings. DataGrip and VS Code connect to the
same server independently; a SQL-file handoff extension does not share sessions.

## Troubleshooting

If the CLI is missing, repeat its installation step above in a new terminal.
For formatting, profile or Sync problems, use the
[recovery troubleshooting table](vscode/recovery.md#troubleshooting).
Stop before replacing settings when the active profile or backup is uncertain.

## Published section links

Existing section bookmarks remain below. Follow the linked task owner for the
complete procedure. New links should point directly to the task page.

<a id="1-choose-and-create-profiles"></a>

Continue with [configure vs code profiles and settings](vscode/profiles.md#1-choose-and-create-profiles).

<a id="create-the-selected-profiles"></a>

Continue with [configure vs code profiles and settings](vscode/profiles.md#create-the-selected-profiles).

<a id="choose-profile-icons"></a>

Continue with [configure vs code profiles and settings](vscode/profiles.md#choose-profile-icons).

<a id="choose-how-resources-are-shared"></a>

Continue with [configure vs code profiles and settings](vscode/profiles.md#choose-how-resources-are-shared).

<a id="2-install-the-final-extension-lists"></a>

Continue with [choose vs code extensions](vscode/extensions.md#2-install-the-final-extension-lists).

<a id="copilot-already-provided-through-your-vs-code-setup"></a>

Continue with [choose vs code extensions](vscode/extensions.md#copilot-already-provided-through-your-vs-code-setup).

<a id="extension-tables"></a>

Continue with [choose vs code extensions](vscode/extensions.md#extension-tables).

<a id="default-extensions"></a>

Continue with [choose vs code extensions](vscode/extensions.md#default-extensions).

<a id="full-stack-extensions"></a>

Continue with [choose vs code extensions](vscode/extensions.md#full-stack-extensions).

<a id="ai-extensions"></a>

Continue with [choose vs code extensions](vscode/extensions.md#ai-extensions).

<a id="operations-extensions"></a>

Continue with [choose vs code extensions](vscode/extensions.md#operations-extensions).

<a id="install-and-share-the-default-baseline"></a>

Continue with [choose vs code extensions](vscode/extensions.md#install-and-share-the-default-baseline).

<a id="reload-optional-shared-convenience"></a>

Continue with [choose vs code extensions](vscode/extensions.md#reload-optional-shared-convenience).

<a id="file-utils-full-stack-file-commands"></a>

Continue with [choose vs code extensions](vscode/extensions.md#file-utils-full-stack-file-commands).

<a id="npm-visual-manager-full-stack-optional-in-ai"></a>

Continue with [choose vs code extensions](vscode/extensions.md#npm-visual-manager-full-stack-optional-in-ai).

<a id="rename-angular-component-full-stack-and-ai"></a>

Continue with [choose vs code extensions](vscode/extensions.md#rename-angular-component-full-stack-and-ai).

<a id="auto-barrel-full-stack-and-ai"></a>

Continue with [choose vs code extensions](vscode/extensions.md#auto-barrel-full-stack-and-ai).

<a id="css-peek-full-stack-optional-in-ai"></a>

Continue with [choose vs code extensions](vscode/extensions.md#css-peek-full-stack-optional-in-ai).

<a id="tailwind-css-full-stack-and-ai"></a>

Continue with [choose vs code extensions](vscode/extensions.md#tailwind-css-full-stack-and-ai).

<a id="3-apply-shared-user-settings"></a>

Continue with [configure vs code profiles and settings](vscode/profiles.md#3-apply-shared-user-settings).

<a id="settings-ownership-matrix"></a>

Continue with [configure vs code profiles and settings](vscode/profiles.md#settings-ownership-matrix).

<a id="editor-tabs"></a>

Continue with [configure vs code profiles and settings](vscode/profiles.md#editor-tabs).

<a id="markdown-formatting"></a>

Continue with [configure vs code profiles and settings](vscode/profiles.md#markdown-formatting).

<a id="show-gitlens-blame-without-editor-clutter"></a>

Continue with [configure vs code profiles and settings](vscode/profiles.md#show-gitlens-blame-without-editor-clutter).

<a id="generate-conventional-commit-messages-with-gitlens"></a>

Continue with [configure vs code profiles and settings](vscode/profiles.md#generate-conventional-commit-messages-with-gitlens).

<a id="4-apply-profile-settings"></a>

Continue with [configure vs code profiles and settings](vscode/profiles.md#4-apply-profile-settings).

<a id="default-overrides"></a>

Continue with [configure vs code profiles and settings](vscode/profiles.md#default-overrides).

<a id="full-stack-overrides"></a>

Continue with [configure vs code profiles and settings](vscode/profiles.md#full-stack-overrides).

<a id="ai-overrides"></a>

Continue with [configure vs code profiles and settings](vscode/profiles.md#ai-overrides).

<a id="operations-overrides"></a>

Continue with [configure vs code profiles and settings](vscode/profiles.md#operations-overrides).

<a id="associate-a-project-with-its-profile"></a>

Continue with [configure vs code profiles and settings](vscode/profiles.md#associate-a-project-with-its-profile).

<a id="5-configure-import-cleanup-and-keyboard-shortcuts"></a>

Continue with [configure editing and language behaviour](vscode/editing.md#5-configure-import-cleanup-and-keyboard-shortcuts).

<a id="choose-one-import-policy"></a>

Continue with [configure editing and language behaviour](vscode/editing.md#choose-one-import-policy).

<a id="useful-built-in-macos-shortcuts"></a>

Continue with [configure editing and language behaviour](vscode/editing.md#useful-built-in-macos-shortcuts).

<a id="new-file-tab-shortcut"></a>

Continue with [configure editing and language behaviour](vscode/editing.md#new-file-tab-shortcut).

<a id="personal-import-shortcuts"></a>

Continue with [configure editing and language behaviour](vscode/editing.md#personal-import-shortcuts).

<a id="6-edit-environment-files"></a>

Continue with [configure editing and language behaviour](vscode/editing.md#6-edit-environment-files).

<a id="7-configure-angular-and-nestjs-folder-icons"></a>

Continue with [configure editing and language behaviour](vscode/editing.md#7-configure-angular-and-nestjs-folder-icons).

<a id="8-configure-angular-html-highlighting"></a>

Continue with [configure editing and language behaviour](vscode/editing.md#8-configure-angular-html-highlighting).

<a id="9-verify-and-export"></a>

Continue with [verify, export and recover vs code](vscode/recovery.md#9-verify-and-export).

<a id="export-and-back-up-the-configuration"></a>

Continue with [verify, export and recover vs code](vscode/recovery.md#export-and-back-up-the-configuration).

<a id="export-a-portable-profile---preferred"></a>

Continue with [verify, export and recover vs code](vscode/recovery.md#export-a-portable-profile---preferred).

<a id="restore-your-own-exported-profile"></a>

Continue with [verify, export and recover vs code](vscode/recovery.md#restore-your-own-exported-profile).

<a id="record-the-extension-inventory"></a>

Continue with [verify, export and recover vs code](vscode/recovery.md#record-the-extension-inventory).

<a id="back-up-the-complete-local-user-folder---recovery-copy"></a>

Continue with [verify, export and recover vs code](vscode/recovery.md#back-up-the-complete-local-user-folder---recovery-copy).

<a id="reset-selected-local-settings-or-profiles"></a>

Continue with [verify, export and recover vs code](vscode/recovery.md#reset-selected-local-settings-or-profiles).

<a id="configure-settings-sync-on-a-new-machine"></a>

Continue with [verify, export and recover vs code](vscode/recovery.md#configure-settings-sync-on-a-new-machine).

<a id="change-or-clear-settings-sync-later"></a>

Continue with [verify, export and recover vs code](vscode/recovery.md#change-or-clear-settings-sync-later).

<a id="10-optional-custom-profile-tech-content-creator"></a>

Continue with [configure vs code profiles and settings](vscode/profiles.md#10-optional-custom-profile-tech-content-creator).
