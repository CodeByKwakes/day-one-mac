[← Phase 2](02-command-line-foundation.md) · **Required Installation Centre** · [Phase 3 →](03-security-and-ssh.md)

# Required Installation Centre

**Time:** 15–45 minutes · **Required:** everyone · **Runs once after Phase 2**

The lists below describe the default **recommended-productivity** preset.
The **core** preset skips Raycast, Warp, the Nerd Font, and VS Code; Phase 7
records a no-op. Both presets retain command-line tools and security gates.
1Password and its CLI are required only for 1Password authentication. Changing
the preset does not uninstall existing software. See [Start here](../../START-HERE.md#run-the-recommended-route).

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

For Raycast specifically, the [Raycast installation guide](../../how-to/apps/RAYCAST.md#step-1--install-or-verify-raycast)
shows the Homebrew, official-download and Company Portal routes, plus the exact
ownership recheck. A valid external installation is accepted and remains
owned by its original installer.

### Required command-line tools

Everyone receives:

```text
git  jq  ripgrep
```

ghq is installed only when explicitly selected alongside the developer layout.
An existing compatible copy is reused without adopting its package ownership.
See [folder choices and optional ghq](../manual/developer-folders.md).

The saved choices add only the relevant tools:

| Choice | Additional Homebrew formulae |
|---|---|
| Local-only or private-repository chezmoi | `chezmoi` |
| Homebrew shell | `zsh`; Apple/keep choices do not request this formula |
| Starship prompt | `starship` |
| Node.js / JavaScript | `fnm`, `pnpm` |
| Python | `uv` |
| Track 1 or 3 (GitHub) | `gh` |
| Track 2 or 3 (Azure DevOps) | `azure-cli` (cask; existing formula installs are accepted) |

A Homebrew command-line package is called a **formula**. A Homebrew macOS app
or font is called a **cask**. See [Glossary](../../reference/GLOSSARY.md) for more terms.

Azure CLI is now distributed as a Homebrew **cask**, even though it is a
command-line tool. Install a missing copy with `brew install --cask azure-cli`;
keep a working existing formula or cask installation. The runner checks both
package types. See the [Homebrew Azure CLI cask](https://formulae.brew.sh/cask/azure-cli).

If version 1.5.0 says Azure CLI is already installed but the Installation Centre
still fails, its formula-only check may be rejecting the cask. Confirm with
`brew list --cask --versions azure-cli` and `az --version`, then update the
Day One Mac runtime to a release containing the fix. Reinstalling the cask
alone cannot repair version 1.5.0's incorrect package-type check.

## Manual route — install and verify each item

Manual-route readers do not run the Installation Centre. Use the catalogue
above to check each item, preserve an existing approved owner, and install only
missing software. Run the version or application check for every item before
continuing to Manual 3. Keep your own record of the selected installer because
the manual route does not create provenance or rollback manifests.

The complete commands and checks are in
[Manual 3 and Manual 4](../manual/MANUAL-SETUP-GUIDE.md#manual-3--configure-git-authentication-and-filevault).

## Script-assisted route — recommended automatic flow

Start or resume the normal wizard:

```bash
day-one-mac --wizard
```

After Phase 2 succeeds, the wizard opens the Installation Centre immediately.
You do not need to start a second command. When all required software is ready,
the wizard continues to Phase 3 configuration.

## Run only this checkpoint

HTTPS users can select `--https-helper gcm` to include the
`git-credential-manager` cask. The wizard recommends this browser sign-in route
for Azure DevOps; `--https-helper existing` keeps an approved existing helper
or PAT/Keychain workflow. Earlier saved HTTPS setups default to `existing`
until you explicitly change the selection. GCM is included even with the core
preset, and approved external installations are reused rather than adopted.
Phase 4 configures the selected providers and checks Git repository access;
installing the helper alone does not prove authentication.

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

Databases, OrbStack, DBeaver, Docker workloads, AI clients, MCP servers,
Obsidian, Purge, VS Code profiles, and enhanced command-line tools remain
optional. They are offered only after the required Phase 8 verification
succeeds. This keeps the base predictable and avoids installing software
merely because it may be useful later.

## Troubleshooting

| Problem | Safe response |
|---|---|
| An app is marked **External installation** | Continue; its current owner remains responsible for updates |
| An app is marked **Needs review** | Stop and resolve the duplicate, receipt, bundle-ID, or location conflict shown |
| Company Portal is slow | Stop safely, finish it later, then rerun `day-one-mac install` |
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
