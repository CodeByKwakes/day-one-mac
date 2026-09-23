[← Day One Mac home](../README.md) · **Required app setup** · [Phase 3 — 1Password →](../01-required/03-security-and-ssh.md)

# Required application setup

The Installation Centre verifies the required desktop applications and asks how to provide only
those that are missing. An existing valid copy from a company portal, the Mac App Store,
or a trusted manual installer is kept as-is. This hub explains when to open
each app, which settings are part of the Day One baseline, and how to move
settings to or from another Mac without accidentally restoring years of
unwanted state.

The command-line tools installed by the Installation Centre—Git, ghq, chezmoi, jq, ripgrep,
Starship, and the track- or stack-specific tools—are already configured in
Phases 4–6. They do not need separate graphical setup guides.

| Other required tools | Complete instructions |
|---|---|
| Xcode Command Line Tools and Homebrew | [Phase 2](../01-required/02-command-line-foundation.md) |
| Git, ghq, GitHub CLI, and Azure CLI | [Phase 4](../01-required/04-core-tools-and-hosting.md) |
| chezmoi and Starship | [Phase 5](../01-required/05-dotfiles-and-shell.md) |
| Node, npm, pnpm, and/or Python with uv | [Phase 6](../01-required/06-language-toolchains.md) |

Their portable state is recorded through the chezmoi source and Phase 8
Brewfile rather than an application export button.

After the first-launch steps, use the consolidated
[keyboard shortcut reference](KEYBOARD-SHORTCUTS.md). It assigns global
shortcuts deliberately and explains the `⌘\` conflict between 1Password
Universal Autofill and Warp Drive.

## What is required

| Application | Installed in | Configuration guide | Required outcome |
|---|---|---|---|
| 1Password and 1Password CLI | Installation Centre; configured in Phase 3 | [Security, new keys, and existing-key import](../01-required/03-security-and-ssh.md); approval policy reference: [1Password SSH approval](1PASSWORD-SSH-APPROVAL.md) | Vault access, CLI integration, provider-compatible keys, and the SSH agent work |
| Raycast | Installation Centre, official download, or company-approved installer | [Install and configure Raycast](RAYCAST.md) · [manual or generated Day One commands](RAYCAST-COMMANDS.md) · [optional AI providers](RAYCAST-AI-PROVIDERS.md) | Opens reliably and has only the permissions you chose |
| Warp | Installation Centre | [Warp setup](WARP.md) | Starts zsh and displays the Starship prompt correctly |
| VS Code | Installation Centre; configured in Phase 7 | [VS Code setup](VSCODE.md) | The `code` command, clean settings, zsh terminal, and font work |
| JetBrains Mono Nerd Font | Installation Centre | [Font check](#check-the-required-font) | Symbols render in Warp and VS Code |

Common shortcuts for all four applications are kept in
[Day One Mac keyboard shortcuts](KEYBOARD-SHORTCUTS.md).

Raycast extensions, Warp Drive workflows, VS Code profiles, AI features, the
OmniRoute gateway, and MCP servers are optional. The required setup succeeds
without them.

## Recommended order

Follow the application guides at these points in the main setup:

1. Complete the Installation Centre so every required application and font is ready.
2. Complete Phase 3 and its 1Password checks.
3. Complete the first-launch sections in the [Raycast](RAYCAST.md) and
   [Warp](WARP.md) guides. Do not import old settings yet.
4. Complete Phase 7 and the [VS Code guide](VSCODE.md).
5. Complete Phase 8 so the required machine state is verified.
6. Export the known-good settings as your new baseline.
7. Import selected old data only if it is still useful.

Raycast AI is not part of the required order. After Phase 8, use the
[provider decision guide](RAYCAST-AI-PROVIDERS.md) only when Raycast AI was
selected and its data route is approved.

This order makes the clean local configuration the reference. A cloud-sync
service or old export cannot silently decide what the new Mac should contain.

## Choose fresh setup or restore

Make this choice separately for every app; you do not need one answer for all
required applications.

| Choice | Use it when | What to do |
|---|---|---|
| **Fresh setup — recommended** | The purpose of this build is a clean start | Configure the small baseline first; archive old exports but do not import them |
| **Selective import** | You need a few shortcuts, snippets, or profiles | Use the app's import checklist and select only known items |
| **Full restore** | The previous app state is trusted and intentionally reproducible | Export the new local state first, then restore and review every category |

Work-managed accounts may apply organization policies or synchronize company
data. Keep work and personal exports separate, and do not put an employer's
settings or private workspace data in a personal repository.

## Create a safe export location

App exports do not belong in this setup repository, whether it is public or
private. Use an encrypted
external volume or a private, access-controlled folder. In examples below,
replace `<backup-volume>` with the name shown in Finder under **Locations**:

```text
/Volumes/<backup-volume>/Day-One-Mac-App-Exports/
├── Raycast/
├── VS-Code/
└── Warp/
```

Before writing to an external volume, confirm that it is connected:

```bash
test -d "/Volumes/<backup-volume>" && echo "Backup volume is mounted"
```

If that command prints nothing, stop and reconnect the volume. Never remove
`/Volumes/<backup-volume>` from a command without replacing it: otherwise a
similarly named folder could be created on the Mac's internal drive.

Treat all exports as private. A VS Code profile can contain sensitive settings,
a Raycast backup contains personal launcher data, and a Warp Drive `.env`
export can contain secrets.

## Check the required font

The Installation Centre verifies the font and asks for Homebrew or another approved installer
only when it is missing. With the portable command installed, run:

```bash
day-one-mac applications --id jetbrains-mono-nerd-font
```

If that command is unavailable, run this from the `day-one-mac/scripts` folder:

```bash
day-one-mac applications --id jetbrains-mono-nerd-font
```

Then select **JetBrainsMono Nerd Font** in both [VS Code](VSCODE.md) and
[Warp](WARP.md). If prompt symbols appear as empty squares:

1. Quit and reopen the affected app so it refreshes the macOS font list.
2. Search that app's settings for `font`.
3. Select **JetBrainsMono Nerd Font**, not plain JetBrains Mono.
4. Open a new terminal and run `starship explain`.

## What the automation does and does not do

The Day One runner:

- identifies whether each required application is managed by Homebrew, the Mac
  App Store, a company portal, or a trusted manual installer;
- offers Homebrew, another approved installer with live recheck, or a safe pause
  when the required application is missing;
- creates a minimal VS Code settings file only when no file exists;
- configures zsh and Starship through chezmoi;
- verifies the applications and VS Code command-line launcher in Phase 8; and
- writes the owner and location to
  `~/.day-one-mac/application-provenance.md`.

It does not:

- sign in to Raycast, Warp, or VS Code;
- enable cloud synchronization;
- import profiles, extensions, shortcuts, or Warp Drive objects;
- grant macOS Accessibility, Screen Recording, or Full Disk Access;
- remove pre-existing application data.

It also never converts an externally managed application into a Homebrew cask
or removes an unselected optional application.

Those choices remain manual because they can expose private data or replace a
known-good local configuration.

## Required app completion checklist 🚦

- [ ] 1Password and its SSH agent pass Phase 3.
- [ ] Raycast opens from `⌘Space`, the Spotlight launcher shortcut is disabled,
      Spotlight indexing remains enabled, and Raycast has only necessary permissions.
- [ ] Warp starts zsh and renders the Starship prompt with the Nerd Font.
- [ ] `code --version` succeeds and VS Code opens a zsh terminal.
- [ ] Cloud sync is either deliberately configured or deliberately left off.
- [ ] A known-good export exists outside the setup repository.
- [ ] Any imported data was reviewed category by category.

---

[← Day One Mac home](../README.md) · [Configure Raycast →](RAYCAST.md) · [Configure Warp →](WARP.md) · [Configure VS Code →](VSCODE.md)
