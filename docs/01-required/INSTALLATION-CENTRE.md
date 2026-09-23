[← Phase 2](02-command-line-foundation.md) · **Required Installation Centre** · [Phase 3 →](03-security-and-ssh.md)

# Required Installation Centre

**Time:** 15–45 minutes · **Required:** everyone · **Runs once after Phase 2**

## Why this checkpoint exists

The setup is easier when software installation and software configuration are
separate. Phase 2 installs Homebrew. This checkpoint then prepares every app,
font, and Terminal tool needed by Phases 3–8. Those later phases can therefore
focus on signing in, choosing settings, and verifying the result.

This is a required checkpoint, not a ninth phase. Its completion is saved and
revalidated just like phase progress. If a required item disappears or the
required catalogue changes, the checkpoint opens again.

## What it installs or accepts

### Required applications and font

- JetBrains Mono Nerd Font
- Raycast
- Visual Studio Code
- Warp
- 1Password and 1Password CLI (`op`) — **only in the `1password` authentication
  mode**, which is the default. Choosing `keychain`, `external`, or `https` in
  [Phase 3 Step 3.0](03-security-and-ssh.md) removes both from this list, and
  the checkpoint stops asking for them.

The checkpoint checks first. An existing, valid app installed by Company
Portal, the Mac App Store, or another approved installer is accepted and left
under that owner's control. A Homebrew installation is not placed over it.

When items are missing, choose one route:

- Press **Enter** to install every missing required item with Homebrew.
- Press **r** to review each missing item separately. This lets a managed Mac
  use Company Portal or another approved installer for selected apps.
- Press **q** to stop safely. Earlier progress stays saved.

If you select an external installer, finish that installer and return to the
Terminal. The checkpoint inspects the real application or command again; it
does not treat a confirmation alone as proof.

For Raycast specifically, the [Raycast installation guide](../10-app-guides/RAYCAST.md#step-1--install-or-verify-raycast)
shows the Homebrew, official-download and Company Portal routes, plus the exact
ownership recheck. A valid external installation is accepted and remains
owned by its original installer.

### Required command-line tools

Everyone receives:

```text
chezmoi  ghq  git  jq  ripgrep  starship  zsh
```

The saved choices add only the relevant tools:

| Choice | Additional Homebrew formulae |
|---|---|
| Node.js / JavaScript | `fnm`, `pnpm` |
| Python | `uv` |
| Track 1 or 3 (GitHub) | `gh` |
| Track 2 or 3 (Azure DevOps) | `azure-cli` |

A Homebrew command-line package is called a **formula**. A Homebrew macOS app
or font is called a **cask**. See [Glossary](../20-reference/GLOSSARY.md) for more terms.

## Recommended automatic flow

Start or resume the normal wizard:

```bash
day-one-mac --wizard
```

After Phase 2 succeeds, the wizard opens the Installation Centre immediately.
You do not need to start a second command. When all required software is ready,
the wizard continues to Phase 3 configuration.

## Run only this checkpoint

Use this after a company installer finishes, after changing track or stack, or
when the status report says the checkpoint needs revalidation:

```bash
day-one-mac install
```

To choose Homebrew for all missing required items without individual prompts:

```bash
day-one-mac install \
  --app-install-policy homebrew
```

## Verification

Show the saved state and perform a live recheck:

```bash
day-one-mac --status
day-one-mac applications --required
```

The status must show:

```text
✓ done  Installation Centre — required software ready
```

Detailed ownership records are written to:

- `~/.day-one-mac/application-provenance.md`
- `~/.day-one-mac/application-provenance.tsv`
- `~/.day-one-mac/install-manifest.tsv`

The install manifest records only items Day One Mac added. That distinction
lets rollback preserve pre-existing and company-managed software.

## What is deliberately not installed here

Databases, OrbStack, Docker workloads, AI clients, MCP servers, Obsidian,
VS Code profiles, and enhanced command-line tools remain optional. They are
offered only after the required Phase 8 verification succeeds. This keeps the
base predictable and avoids installing software merely because it may be
useful later.

## Troubleshooting

| Problem | Safe response |
|---|---|
| An app is marked **External installation** | Continue; its current owner remains responsible for updates |
| An app is marked **Needs review** | Stop and resolve the duplicate, receipt, bundle-ID, or location conflict shown |
| Company Portal is slow | Stop safely, finish it later, then rerun `--install-centre` |
| Homebrew reports a network error | Check Wi-Fi, VPN, proxy, DNS, and system time; rerun the checkpoint |
| A later phase says software is missing | Rerun `day-one-mac install`; the phase will not silently install it |
| Track or stack changed | Rerun the checkpoint so its conditional formulae are revalidated |

## Completion checklist 🚦

- [ ] Every required application/font entry for your authentication mode is
      present with an understood owner — six in `1password` mode, four otherwise.
- [ ] Every formula for the selected track and stack is installed.
- [ ] No ownership conflict remains.
- [ ] `--status` reports the Installation Centre as current.
- [ ] Continue to Phase 3 for account, SSH, and FileVault configuration.

---

[← Phase 2](02-command-line-foundation.md) · [Continue to Phase 3 →](03-security-and-ssh.md)
