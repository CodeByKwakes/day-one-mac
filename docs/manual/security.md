[← Manual handbook](README.md)

# Security setup: choose one key owner

**Audience:** first-time setup and maintainers reviewing security boundaries.
**Outcome:** encrypted storage, recoverable account access, working repository
authentication, and separately verified commit signing if you choose it.

## Before starting

On a managed Mac, confirm employer policy before creating keys, installing a
password manager, or connecting a personal account. On an existing Mac, inventory
the current configuration and preserve a recoverable copy before editing it.
Never paste private keys, recovery codes, passwords or tokens into a terminal
command, chat, screenshot, public dotfiles repository or acceptance report.

Choose **one route for each identity**. Do not run both tutorials against the
same provider block. Multiple work/personal identities need explicit host aliases
and Git routing; use [Module 18](../03-advanced/18-hosting-identities-azure-and-worktrees.md).

| Choice | Where the private key lives | What remains manual | Start here |
|---|---|---|---|
| 1Password | SSH Key item in the selected vault; a public pin may live in `~/.ssh` | Account recovery, key selection, provider registration, approvals | [1Password walkthrough](1password.md) |
| Apple Keychain-backed SSH | Encrypted private-key file in `~/.ssh`; Keychain remembers its passphrase | Non-empty passphrase, secure backup or replacement plan, registration | [Keychain walkthrough](keychain-ssh.md) |
| Existing external agent | Wherever that agent stores keys; Day One Mac does not create a new private key | Agent setup, availability, key policy and recovery | [Phase 3 modes](../01-required/03-security-and-ssh.md) |
| HTTPS | Provider credential manager/session, not an SSH authentication key | Browser sign-in, credential storage and repository access | [Phase 4](../01-required/04-core-tools-and-hosting.md) |

Keychain-backed SSH does **not** move the private key into Keychain, and is not
an iCloud backup guarantee. HTTPS authentication does not prevent separate SSH
commit signing. Neither SSH authentication nor signing replaces disk encryption.

## Follow the setup in order

1. Choose an account/identity and recovery method; enable the provider's MFA.
2. Complete FileVault and recovery below.
3. Follow the chosen key-owner tutorial, then register **public** keys.
4. Verify the host fingerprint and authenticate to the intended provider.
5. Set the correct Git author name/email and test access to an authorised repo.
6. If required, configure and test [SSH signing](ssh-signing-and-recovery.md).
7. Review chezmoi changes and backup boundaries; record only non-secret evidence.

The tutorials distinguish two routes:

- **Script-assisted:** select the authentication mode in required setup. The
  Installation Centre supplies missing components under your app policy; Phase
  3 prepares/checks the selected SSH route, and Phase 4 handles hosting setup.
  Use the tutorial's shared manual steps, not duplicate configuration snippets.
- **Entirely manual:** follow the [manual baseline](../20-reference/MANUAL-SETUP-GUIDE.md)
  and the tutorial's manual configuration. No Day One Mac scripts are required.

The runner can check files, binaries and responses. It cannot decide who should
have account access, prove a recovery code works without an exercise, or infer
that every repository is authorised. Module 18's metadata checks are not a real
signature test. Reading this handbook never completes a phase.

## Private package registry credentials

For a project using private npm packages, follow
[Azure Artifacts npm authentication](azure-artifacts-npm.md). This is an optional,
separate credential flow: Git/SSH login does not authenticate npm. Keep raw and
encoded PATs out of setup state, acceptance evidence, and plaintext dotfiles
repositories, including private ones.

## FileVault and recovery

In **System Settings → Privacy & Security → FileVault**, inspect the current
state. If disabled, choose **Turn On** and follow the displayed recovery choices
or your organisation's escrow policy. Preserve the chosen recovery method away
from this Mac; do not keep its only copy on the disk it unlocks. Check:

```bash
fdesetup status
```

Record the status and recovery-method availability, never the key. A VM's result
is evidence for that guest only, not the physical host. Do not turn encryption
off just to match a test baseline. Apple's [FileVault guide](https://support.apple.com/guide/mac-help/protect-data-on-your-mac-with-filevault-mh11785/mac)
explains the platform's recovery choices.

## Completion checklist

- [ ] The selected account can be recovered without relying solely on this Mac.
- [ ] FileVault is enabled, or an explicit policy exception is documented.
- [ ] Only intended keys are offered to each provider; fingerprints were checked.
- [ ] Authentication identifies the expected account; one authorised repo is readable.
- [ ] A test signature verifies if signing is enabled; it is not inferred from login.
- [ ] No private keys, account sessions or recovery material entered dotfiles Git.
- [ ] Restart/lock behaviour is tested, and recovery/rotation ownership is recorded.

For failures, rotation and changing authentication modes, use
[signing and recovery](ssh-signing-and-recovery.md). For the exact scripted gates,
keep [Phase 3](../01-required/03-security-and-ssh.md) and
[Phase 4](../01-required/04-core-tools-and-hosting.md) as the runner reference.
