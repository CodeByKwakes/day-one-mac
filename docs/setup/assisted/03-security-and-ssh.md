[← Installation Centre](INSTALLATION-CENTRE.md) · **Phase 3** · [Phase 4 →](04-core-tools-and-hosting.md)

# Phase 3 — Security, 1Password, and SSH

For a route-focused beginner walkthrough, start with the
[security learning path](../manual/security/README.md): separate 1Password and Keychain
tutorials, provider registration, real signing verification and recovery. This
phase page remains the detailed reference for the runner's gates.

**Time:** 30-60 minutes · **Required:** everyone

## Outcome

Git can authenticate to the providers your track selected, and FileVault
protects the disk.

How Git authenticates is your choice - see [Step 3.0](#step-30--choose-how-git-authenticates).
In the default **1Password** mode, its CLI and SSH agent are enabled, the
providers know the public key, and **no new private SSH key file is
written to `~/.ssh`**. That last guarantee holds in every mode except
`keychain`, which creates a passphrase-protected key file on purpose.

If an existing key is imported, its old disk copy is retained until
authentication has been tested and you deliberately archive or remove that
redundant copy. Selecting 1Password does not authorise deleting existing keys.
Phase 8 checks the selected authentication route separately from existing key
storage. An encrypted legacy key needs an explicit retention review; an
unprotected or unverifiable key remains a blocker. See
[Phase 8's key review](08-verify-and-reproduce.md#ssh-authentication-and-existing-key-storage).

> 🏢 **Company-policy note:** If policy prohibits 1Password, you do not have to
> stop. Choose another mode in Step 3.0. Do not install an unapproved
> credential tool to satisfy a gate.

## How to use this phase

Choose the authentication mode in Step 3.0 before following a branch.

- **Manual route:** use the matching branch in
  [Manual 3](../manual/security/README.md)
  and the relevant provider steps below. Do not run Step 3.9.
- **Script-assisted route:** complete the applicable shared manual actions in
  the app, browser, and System Settings, then run Step 3.9 once. The script
  cannot approve those actions for you.

| Step | What you do | Where |
|---|---|---|
| 3.0 | Choose how Git authenticates | Decision |
| 3.1 | Confirm 1Password and its CLI are installed | Terminal |
| 3.2 | Turn on the CLI integration and the SSH agent | 1Password |
| 3.3 | Set the SSH approval policy | 1Password |
| 3.4 | Set up GitHub authentication | 1Password, Browser or Terminal |
| 3.5 | Set up Azure DevOps authentication | 1Password, Browser or Terminal |
| 3.6 | Track 4: choose repository access methods | Browser or Terminal |
| 3.7 | Pin the intended provider key (required by the 1Password runner) | Terminal |
| 3.8 | Turn on FileVault | System Settings |
| 3.9 | Run the phase | Terminal |

GitHub registration can use a browser or `gh`; Azure SSH registration uses
the browser. Both provider sections explain their complete path.

The Installation Centre already installed or accepted 1Password and its CLI.
Phase 3 configures them; it does not install anything. If a component is
missing, run `day-one-mac install` first.

**Never paste, upload, or print the private-key field.** Only public keys leave
1Password.

An **SSH agent** is a local service that proves your identity to Git without
copying the private key into `~/.ssh`. A **socket** is the local connection file
used to reach that service. More terms are defined in [GLOSSARY.md](../../shared/glossary.md).

### Choose your provider path

Complete the shared authentication preparation, then follow **Step 3.4 for
GitHub**, **Step 3.5 for Azure DevOps**, or both for Track 3. Each provider
section includes key creation/import, agent checks, registration, pinning and
verification. **Step 3.6 is Track 4: none of the above**, with independent
repository access methods grouped by provider. Finish FileVault and the
script-assisted phase gate after your chosen path.

## Step 3.0 — Choose how Git authenticates

Day One Mac supports four ways to prove your identity to GitHub or Azure
DevOps. Pick one before going further; the rest of this phase follows your
choice.

| Mode | What it uses | Private key in `~/.ssh`? | Choose it when |
|---|---|---|---|
| **`1password`** *(default)* | The 1Password SSH agent | **No** | You use 1Password, or can. The strongest option, and the one the rest of this guide walks through |
| **`keychain`** | A key file in `~/.ssh`, passphrase held by the macOS Keychain | **Yes, deliberately** | You want the standard Mac setup with no password manager |
| **`external`** | Whatever agent you already run | No | You use Secretive, a YubiKey, or a company-managed agent |
| **`https`** | No SSH at all - Git over HTTPS | No | SSH is blocked on your network, or you would rather not manage keys |

Set it in the wizard, or directly:

```bash
day-one-mac setup --phase 03 --auth-mode keychain
```

Check what is currently saved at any time:

```bash
day-one-mac --status
```

```text
  Git authentication: 1password
```

Changing the mode later reopens Phases 3 and 4, because both depend on it.

### What each mode changes

- **`1password`** - Steps 3.1 to 3.7 as written below.
- **`keychain`** - skip Steps 3.1-3.3. Phase 3 runs `ssh-keygen` for you, which
  prompts for a non-empty passphrase; the runner never sees it. It then adds the key to
  the macOS Keychain and writes `UseKeychain yes` into `~/.ssh/config`. You
  still register the public key with your provider (Step 3.4 or 3.5), using
  `~/.ssh/id_ed25519.pub` or `~/.ssh/id_rsa_azure.pub`.
- **`external`** - skip shared Steps 3.1-3.3 and the 1Password generation/pin steps. Load a key into your own agent so
  `ssh-add -l` lists it, then follow the registration steps in Step 3.4 or 3.5. Day One Mac creates nothing and only
  checks an identity is available.
- **`https`** - skip the SSH setup. Follow the HTTPS methods in Step 3.6,
  then complete Step 3.8 (FileVault); Phase 4 configures the selected
  GCM or GitHub CLI helper, or reuses the existing Azure helper, on Tracks 1-3.

**FileVault (Step 3.8) is required in every mode.**

### Keychain mode: an empty passphrase stops setup

Do not press Return at both passphrase prompts without entering a value.
Phase 3 checks new and existing keys before adding them to the agent. An
unprotected, unreadable or unrecognised key stops the phase; a failed Keychain
load also stops it. No rejected key is deleted or replaced automatically.

If you accidentally created a GitHub key without a passphrase, run:

```bash
ssh-keygen -p -f "$HOME/.ssh/id_ed25519"
```

Enter the old passphrase (Return if it was empty), then enter and confirm a
non-empty new passphrase privately. For Azure, use `~/.ssh/id_rsa_azure`
instead. This changes protection of the same key, not the public key registered
with your provider. Rerun Phase 3 afterward. Do not put your passphrase in a
command, screenshot or chat message.

The protection check tries an empty passphrase without interactive input. A
successful read means the key is unprotected; OpenSSH's explicit incorrect-
passphrase response identifies encryption. Other errors are **unverifiable**,
not a pass. Phase 8 repeats this check for each selected provider key. This
does not measure passphrase strength or prove provider access.

Managed SSH configuration now uses the mode-neutral `Day One Mac: SSH
authentication` markers. Phase 3 recognises and migrates the former
`Day One Mac: 1Password SSH agent` pair while keeping unrelated settings.
Incomplete, nested, mixed or multiple managed blocks require manual review.

## Step 3.1 — Confirm 1Password is installed

Run `day-one-mac applications --id 1password --id 1password-cli` only in
1Password mode. Expected result: both selected payloads are ready with their
existing owner. Return to the Installation Centre for a missing component.
Open the app and complete sign-in/recovery through the linked manual task.

### Current-version check

Complete the relevant action in the [manual task](../manual/security/1password.md), then return
to this phase. Preserve existing credentials and configuration; verify the
result before rerunning the gate.

## Step 3.2 — Turn on the developer integrations

Shared manual action, 1Password mode only: configure the selected developer
integrations and approval policy in the [1Password task](../manual/security/1password.md).
Expected result: the intended unlocked account answers the CLI/agent checks.
Return here without creating a second SSH configuration block.

## Step 3.3 — Set the SSH approval policy

Shared manual action, 1Password mode only: configure the selected developer
integrations and approval policy in the [1Password task](../manual/security/1password.md).
Expected result: the intended unlocked account answers the CLI/agent checks.
Return here without creating a second SSH configuration block.

## Step 3.4 — GitHub setup

For GitHub, select the intended modern identity; the project baseline uses
Ed25519 for new keys. For 1Password, create/import it through the
[manual key-owner task](../manual/security/1password.md). For Keychain mode,
let this runner create/reuse the selected passphrase-protected provider key.
External-agent mode reuses the approved key owner; HTTPS skips SSH registration.

Register only the public key through the
[provider registration task](../manual/security/ssh-signing-and-recovery.md#register-public-keys-and-test-authentication).
Expected result: the registered fingerprint matches the intended identity and
required organisation approval is complete. Keep an imported key's original
secure copy until provider access and recovery are verified. Return here for
pin selection; Phase 4 separately proves repository access.

### Create or import a GitHub key — Create a new Ed25519 key for GitHub

Complete the relevant action in the [manual task](../manual/security/ssh-signing-and-recovery.md#register-public-keys-and-test-authentication), then return
to this phase. Preserve existing credentials and configuration; verify the
result before rerunning the gate.

### Import a trusted existing key

Complete the relevant action in the [manual task](../manual/security/ssh-signing-and-recovery.md#register-public-keys-and-test-authentication), then return
to this phase. Preserve existing credentials and configuration; verify the
result before rerunning the gate.

### Confirm the agent can see your key

Complete the relevant action in the [manual task](../manual/security/ssh-signing-and-recovery.md#register-public-keys-and-test-authentication), then return
to this phase. Preserve existing credentials and configuration; verify the
result before rerunning the gate.

### First: copy the public key

Complete the relevant action in the [manual task](../manual/security/ssh-signing-and-recovery.md#register-public-keys-and-test-authentication), then return
to this phase. Preserve existing credentials and configuration; verify the
result before rerunning the gate.

### Add the key to GitHub manually

Complete the relevant action in the [manual task](../manual/security/ssh-signing-and-recovery.md#register-public-keys-and-test-authentication), then return
to this phase. Preserve existing credentials and configuration; verify the
result before rerunning the gate.

### Add the key to GitHub with a script

Complete the relevant action in the [manual task](../manual/security/ssh-signing-and-recovery.md#register-public-keys-and-test-authentication), then return
to this phase. Preserve existing credentials and configuration; verify the
result before rerunning the gate.

### Pin and test the github key

Complete the relevant action in the [manual task](../manual/security/ssh-signing-and-recovery.md#register-public-keys-and-test-authentication), then return
to this phase. Preserve existing credentials and configuration; verify the
result before rerunning the gate.

## Step 3.5 — Azure DevOps setup 🏢

For Azure DevOps, select the intended RSA identity; the project baseline uses
RSA 3072 for new keys. For 1Password, create/import it through the
[manual key-owner task](../manual/security/1password.md). For Keychain mode,
let this runner create/reuse the selected passphrase-protected provider key.
External-agent mode reuses the approved key owner; HTTPS skips SSH registration.

Register only the public key through the
[provider registration task](../manual/security/ssh-signing-and-recovery.md#register-public-keys-and-test-authentication).
Expected result: the registered fingerprint matches the intended identity and
required organisation approval is complete. Keep an imported key's original
secure copy until provider access and recovery are verified. Return here for
pin selection; Phase 4 separately proves repository access.

### Create or import an Azure DevOps key — Create a new RSA key for Azure DevOps 🏢

Complete the relevant action in the [manual task](../manual/security/ssh-signing-and-recovery.md#register-public-keys-and-test-authentication), then return
to this phase. Preserve existing credentials and configuration; verify the
result before rerunning the gate.

### Import a trusted existing key

Complete the relevant action in the [manual task](../manual/security/ssh-signing-and-recovery.md#register-public-keys-and-test-authentication), then return
to this phase. Preserve existing credentials and configuration; verify the
result before rerunning the gate.

### Confirm the agent can see your key

Complete the relevant action in the [manual task](../manual/security/ssh-signing-and-recovery.md#register-public-keys-and-test-authentication), then return
to this phase. Preserve existing credentials and configuration; verify the
result before rerunning the gate.

### First: copy the public key

Complete the relevant action in the [manual task](../manual/security/ssh-signing-and-recovery.md#register-public-keys-and-test-authentication), then return
to this phase. Preserve existing credentials and configuration; verify the
result before rerunning the gate.

### Add the key to Azure DevOps 🏢

Complete the relevant action in the [manual task](../manual/security/ssh-signing-and-recovery.md#register-public-keys-and-test-authentication), then return
to this phase. Preserve existing credentials and configuration; verify the
result before rerunning the gate.

### Pin and test the azure key

Complete the relevant action in the [manual task](../manual/security/ssh-signing-and-recovery.md#register-public-keys-and-test-authentication), then return
to this phase. Preserve existing credentials and configuration; verify the
result before rerunning the gate.

## Step 3.6 — Track 4: none of the above

For self-managed hosting, choose the provider and authentication owner in the
[manual security task](../manual/security/README.md). Do not infer a provider
from a directory name. HTTPS users follow the [helper task](../manual/security/https-git.md);
GitHub/Azure CLI sign-in and repository read access remain separate checks.
Expected result: the selected provider documents a supported access method and
you can identify its authorised repository URL.

### GitHub repository access

Complete the relevant action in the [manual task](../manual/security/https-git.md), then return
to this phase. Preserve existing credentials and configuration; verify the
result before rerunning the gate.

### Azure DevOps repository access 🏢

Complete the relevant action in the [manual task](../manual/security/https-git.md), then return
to this phase. Preserve existing credentials and configuration; verify the
result before rerunning the gate.

### Other hosts and repository tools

Complete the relevant action in the [manual task](../manual/security/https-git.md), then return
to this phase. Preserve existing credentials and configuration; verify the
result before rerunning the gate.

## Step 3.7 — Pin provider keys when needed

**Script-assisted 1Password route:** each selected provider needs a verified
public-key pin before Phase 3 writes its SSH configuration. This also applies
when the agent currently offers only one key: adding another key later must
not silently change which identity Git uses.

**Manual route:** pinning is recommended, and is especially important on
Track 3 or when several unrelated keys are visible. Azure accepts the first
key offered and will not try a second. Follow **The manual way** below without
running Day One Mac commands.

Doing this now, before Step 3.9, means the runner picks the files up on its
first run.

The filenames matter - the runner looks for these exact names. These are public
files; the private keys never leave 1Password.

### The quick way

Let Day One Mac read the key out of 1Password and save it for you:

```bash
day-one-mac ssh-pin
```

With no argument it follows your **saved hosting track**, so it writes exactly
the files your providers need and nothing else:

| Track | What `day-one-mac ssh-pin` writes |
|---|---|
| 1 - GitHub | `~/.ssh/github-auth.pub` |
| 2 - Azure DevOps | `~/.ssh/azure-devops-auth.pub` |
| 3 - both | both files |

On Track 3 that looks like:

```text
  ✓ saved the GitHub public key to /Users/your-name/.ssh/github-auth.pub
  ✓ saved the Azure DevOps public key to /Users/your-name/.ssh/azure-devops-auth.pub
```

To do one provider at a time - useful when only one key has changed - name it:

```bash
day-one-mac ssh-pin github
day-one-mac ssh-pin azure
```

The command finds candidates by provider name in their SSH Key titles and
excludes titles labelled as signing keys. Titles are discovery hints, not
proof of identity. It does **not** prefer a title containing “Authentication”
over another candidate.

When several candidates remain, choose their displayed number, or enter `q`
to cancel. Each row includes the stable item ID, so duplicate titles remain
distinct. `--yes` cannot choose between identities; non-interactive ambiguity
stops without changing that provider's pin.

The command requests only the selected item's `public key` field by ID, never
the full item or its private key. It parses the key with OpenSSH and checks its
SHA256 fingerprint against the **1Password** agent, not whichever agent your
shell normally uses. Azure pins must themselves be RSA keys.

Before saving, review the item title, ID, fingerprint and destination in the
confirmation prompt. Confirm that this is the intended key from Step 3.4 and
that its fingerprint matches the provider registration in Step 3.4 or 3.5. A match
with the local agent alone does not prove access to your provider account.

If a key is not offered by the agent, the command stops:

```text
  ⚠ The selected github key (SHA256:ExampleFingerprint) is not offered by the 1Password SSH agent.
```

Phase 3 offers this flow when a pin is missing. Declining, failing retrieval,
or finding a mismatched existing pin leaves the phase incomplete **before**
the SSH configuration and its chezmoi copy are changed. Existing pins are
checked again on reruns; they are never silently replaced to satisfy the gate.
The command also refuses symlink pin paths. On Track 3 each provider is a
separate operation: a successfully saved first pin remains if the second fails.

If retrieval fails, the command reports a sanitized error rather than printing
the raw 1Password response. Check the 1Password app and CLI integration, then
retry or use **The manual way** below. A timeout is reported separately; it
does not mean the key is missing.

### The manual way

If you would rather not involve the CLI - or `op` is unavailable - open the SSH
Key item in 1Password and choose **Copy Public Key**, then write the clipboard
straight to the file so nothing is retyped or truncated:

```bash
mkdir -p ~/.ssh
pbpaste > ~/.ssh/github-auth.pub          # after copying the GitHub public key
```

Repeat for Azure DevOps if your track needs it, copying that item's public key
first:

```bash
pbpaste > ~/.ssh/azure-devops-auth.pub    # after copying the Azure public key
```

Create only the files your track needs, then set safe permissions:

```bash
chmod 700 ~/.ssh
chmod 644 ~/.ssh/github-auth.pub
chmod 644 ~/.ssh/azure-devops-auth.pub    # only if you created it
```

### Either way, confirm the result

Confirm each file you created holds a single public key. Run this for whichever
files your track produced:

```bash
for pub in ~/.ssh/github-auth.pub ~/.ssh/azure-devops-auth.pub; do
  [ -f "$pub" ] && ssh-keygen -l -E sha256 -f "$pub"
done
```

On Track 3:

```text
256 SHA256:AbCdEf123456ExampleFingerprint GitHub — Personal — Authentication (ED25519)
3072 SHA256:ZyXwVu987654ExampleFingerprint Azure DevOps — Work — Authentication (RSA)
```

Every fingerprint must match the intended line from your provider’s agent check and the provider
registration. If an existing pin differs, preserve a copy, review the correct
item in 1Password, then explicitly rerun `day-one-mac ssh-pin github` (or
`azure`) to replace it, or repeat the manual public-key copy. Do not broaden
the agent's allow-list to unrelated keys merely to make the check pass.

Step 3.9 then adds an `IdentityFile` line
for each file it finds, which tells OpenSSH exactly which identity to request
from the agent for that host.

## Step 3.8 — Turn on FileVault 🔴

Shared manual action: complete [FileVault and recovery](../manual/macos.md#4-enable-and-verify-filevault).
Expected result: `fdesetup status` reports FileVault is on and the approved
recovery method is retained independently. Return here and rerun the gate.

## Step 3.9 — Run the phase

After the selected manual actions pass, run the gate:

```bash
day-one-mac setup --phase 03
```

The runner verifies ownership of both 1Password components, prints their
versions, checks that `op account list` really works, lists the identities your
agent offers, and verifies each provider pin and key type before writing the
SSH config. It then checks FileVault. A successful Track 1 run ends like this:

```text
  ℹ 1Password for Mac 8.12.36
  ℹ 1Password CLI 2.39.0
  ✓ 1Password CLI integration answers 'op account list'
  ℹ The SSH agent currently offers:
  ℹ   256 SHA256:AbCdEf123456ExampleFingerprint GitHub — Personal — Authentication (ED25519)
  ✓ 1Password SSH agent exposes at least one usable identity
  ✓ FileVault is on
  ✓ Authentication configuration (1password) and FileVault verified locally
  ℹ Provider authentication is checked separately in Phase 4.
```

Anything still manual returns a clear incomplete status with the next action,
rather than being marked successful.

Provider authentication itself is tested in Phase 4, once `gh` or `az` is
installed for your track.

### Reference — what the runner writes to `~/.ssh/config`

You do not edit this by hand. The runner maintains a marked, **track-specific**
block at the top of the file. Track 1 in 1Password mode receives:

```sshconfig
# >>> Day One Mac: SSH authentication >>>
Host github.com
    HostName github.com
    User git
    IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    ServerAliveInterval 60
    ServerAliveCountMax 3
# <<< Day One Mac: SSH authentication <<<
```

In 1Password mode, each selected host also gets its verified pin:

```sshconfig
    IdentityFile ~/.ssh/github-auth.pub
    IdentitiesOnly yes
```

`IdentitiesOnly yes` appears **only** next to an `IdentityFile`. On its own it
would restrict OpenSSH to the default `~/.ssh/id_rsa`, `~/.ssh/id_ecdsa`, and
`~/.ssh/id_ed25519` files - which 1Password mode deliberately never creates - so
the 1Password agent's keys would never be offered and every push would fail with
`Permission denied (publickey)`. Never add that line by hand to a block with no
`IdentityFile`.

The block targets only your selected providers; it does not force the 1Password
agent onto unrelated company servers. Existing host-specific settings stay below
it. The runner handles an existing file conservatively:

- a missing config is created;
- an existing Day One Mac block is refreshed in place;
- a pre-existing Day One Mac block that targets only `Host *` is migrated
  automatically;
- any other existing config is backed up through the rollback manifest, and the
  runner asks before inserting its block at the top; and
- a symbolic-link config is never replaced indirectly - edit its source instead.

Declining the merge changes nothing and leaves the phase incomplete. The saved
original can be restored later by the Day One Mac rollback tool.

If you have already completed Phase 5, `~/.ssh/config` is managed by chezmoi. The
runner refreshes the chezmoi source for you and prints
`refreshed the chezmoi source for ~/.ssh/config`. If it reports that it could
not, run `chezmoi add ~/.ssh/config` yourself and check `chezmoi diff` :
otherwise a later `chezmoi apply` would revert these provider blocks.

File permissions should be:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/config
```

Do not run `chmod -R 600 ~/.ssh` - directories need execute permission. Do not
use `sudo` on files your own account owns.

## Troubleshooting

| Symptom | Resolution |
|---|---|
| `op: command not found` | Run `day-one-mac applications --id 1password-cli`; if it is missing add `--install-missing`, then open a new terminal |
| `op account list` reports `connecting to desktop app` | Turn on **Integrate with 1Password CLI** in Settings → Developer and unlock the app (Step 3.2) |
| The runner says `op account list` did not finish in 20 seconds | A 1Password prompt is waiting; approve or dismiss it, keep the app unlocked, then rerun Phase 3 |
| `ssh-add -l` cannot connect to an agent | Confirm `SSH_AUTH_SOCK` exactly matches the Group Containers socket in your provider section |
| `The agent has no identities` | Work through the five agent checks in your provider section |
| The runner says the agent offers no RSA identity | Azure DevOps needs RSA; create or import one with Step 3.5 |
| The selected pin is not offered by the 1Password agent | Unlock 1Password; compare the pin, intended item and agent fingerprints. Review the agent allow-list for that intended key. If the pin is wrong, preserve it and explicitly replace it using Step 3.7. SSH configuration remains unchanged on this refusal. |
| Several SSH items match, even though one says “Authentication” | Choose the intended item number interactively and confirm its fingerprint. `--yes` cannot resolve this choice; duplicate titles are distinguished by item ID. |
| Azure rejects an Ed25519 key | Same cause - Azure accepts RSA only |
| Azure fails while several agent keys are visible | Pin the Azure key with Step 3.7; Azure accepts the first key offered |
| An imported key shows a different fingerprint | Stop; the private key and expected public key are not the same pair |
| `gh ssh-key add` reports `HTTP 404` or a missing scope | Run `gh auth refresh --hostname github.com --scopes write:public_key`, then retry (Step 3.4) |
| `gh ssh-key add` reports `key is already in use` | The key is already registered - list it with `gh ssh-key list` and compare fingerprints instead of adding it twice |
| Azure DevOps rejects a pasted key | Re-copy it as one line; an editor-wrapped key with line breaks is invalid (Step 3.5) |
| Provider later reports `Permission denied (publickey)` | Confirm the exact public key is registered on that account, and that SSO is authorized for the organization |
| FileVault cannot be enabled | Use the approved administrator/elevation process and finish approved macOS updates |

## Phase 3 completion checklist 🚦

- [ ] The authentication mode in `day-one-mac --status` is the one you intended.
- [ ] **1password mode:** 1Password is signed in and recoverable.
- [ ] In 1Password mode, the ownership check reports 1Password and its CLI as ready, whether Homebrew or an approved external installer owns them.
- [ ] In 1Password mode, `op account list` returns a table, and the runner confirmed it.
- [ ] In 1Password mode, the SSH agent is enabled.
- [ ] In 1Password mode, SSH approval uses **Application and terminal session** plus **Until
      1Password locks**, or a consciously reviewed alternative from
      [the approval guide](../manual/security/1password.md).
- [ ] In SSH modes, `ssh-add -l` lists at least one identity, and its fingerprint matches what
      the provider shows.
- [ ] In SSH modes, GitHub uses Ed25519 or a reviewed modern RSA key; Azure DevOps uses RSA.
- [ ] In SSH modes, the public key is registered with every provider the track requires :
      manually or with `gh ssh-key add` - and SSO is authorized where the
      organization needs it.
- [ ] In managed SSH modes, `~/.ssh/config` contains the marked Day One Mac block for every selected provider.
- [ ] In the script-assisted 1Password route, every selected provider has a
      public `IdentityFile` pin whose fingerprint matches the intended agent
      key and provider registration.
- [ ] The selected authentication route works independently of the legacy-key
      inventory. Expected Keychain provider keys are passphrase-protected;
      other encrypted keys need explicit Phase 8 retention review. Unprotected
      or unverifiable keys must be resolved, not hidden by renaming them.
- [ ] Any imported old disk copy remains quarantined until provider
      verification succeeds.
- [ ] `fdesetup status` reports FileVault is on.

References: [1Password stable releases](https://releases.1password.com/mac/stable/),
[1Password SSH quick start](https://www.1password.dev/ssh/get-started),
[1Password SSH authorization](https://www.1password.dev/ssh/agent/authorization),
[1Password CLI releases](https://app-updates.agilebits.com/product_history/CLI2),
[1Password key generation and import](https://www.1password.dev/ssh/manage-keys),
[1Password multiple-key routing](https://www.1password.dev/ssh/agent/advanced),
[GitHub SSH keys](https://docs.github.com/en/authentication/connecting-to-github-with-ssh),
and [Azure DevOps SSH authentication](https://learn.microsoft.com/azure/devops/repos/git/use-ssh-keys-to-authenticate).

---

[← Installation Centre](INSTALLATION-CENTRE.md) · [Continue to Phase 4 →](04-core-tools-and-hosting.md)
