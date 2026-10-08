[← Installation Centre](INSTALLATION-CENTRE.md) · **Phase 3** · [Phase 4 →](04-core-tools-and-hosting.md)

# Phase 3 — Security, 1Password, and SSH

For a route-focused beginner walkthrough, start with the
[security learning path](../manual/security.md): separate 1Password and Keychain
tutorials, provider registration, real signing verification and recovery. This
phase page remains the detailed reference for the runner's gates.

**Time:** 30–60 minutes · **Required:** everyone

## Outcome

Git can authenticate to the providers your track selected, and FileVault
protects the disk.

How Git authenticates is your choice — see [Step 3.0](#step-30--choose-how-git-authenticates).
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
  [Manual 3](../20-reference/MANUAL-SETUP-GUIDE.md#manual-3--configure-git-authentication-and-filevault)
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
used to reach that service. More terms are defined in [GLOSSARY.md](../20-reference/GLOSSARY.md).

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
| **`https`** | No SSH at all — Git over HTTPS | No | SSH is blocked on your network, or you would rather not manage keys |

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

- **`1password`** — Steps 3.1 to 3.7 as written below.
- **`keychain`** — skip Steps 3.1–3.3. Phase 3 runs `ssh-keygen` for you, which
  prompts for a non-empty passphrase; the runner never sees it. It then adds the key to
  the macOS Keychain and writes `UseKeychain yes` into `~/.ssh/config`. You
  still register the public key with your provider (Step 3.4 or 3.5), using
  `~/.ssh/id_ed25519.pub` or `~/.ssh/id_rsa_azure.pub`.
- **`external`** — skip shared Steps 3.1–3.3 and the 1Password generation/pin steps. Load a key into your own agent so
  `ssh-add -l` lists it, then follow the registration steps in Step 3.4 or 3.5. Day One Mac creates nothing and only
  checks an identity is available.
- **`https`** — skip the SSH setup. Follow the HTTPS methods in Step 3.6,
  then complete Step 3.8 (FileVault); Phase 4 configures the selected
  provider helper on Tracks 1–3.

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

Check that both the app and the command-line tool are present and see who owns
them:

```bash
day-one-mac applications --id 1password --id 1password-cli
```

Both rows must report as ready. **External installation** is a valid result — it
means Company Portal, the Mac App Store, or another approved installer owns the
app, and Day One Mac will leave it alone. See
[Application ownership](../20-reference/APPLICATION-OWNERSHIP.md).

If either is missing, return to the [Installation Centre](INSTALLATION-CENTRE.md).
On a personal Mac the equivalent manual command is:

```bash
brew install --cask 1password 1password-cli
```

Now open 1Password from `/Applications`, sign in, and finish device approval.
Make sure the account can be recovered before you rely on it for Git
authentication.

Confirm the command-line tool answers:

```bash
op --version
```

```text
2.39.0
```

Your version will differ and that is fine — nothing here is pinned.

### Current-version check

<!-- day-one-mac:version-review 2026-09-19 -->

This phase was checked against **1Password for Mac 8.12.36** and
**1Password CLI 2.39.0**, the current stable releases on **19 September 2026**,
plus the current 1Password Developer documentation. Recheck these numbers every
six months; `./validate.sh` prints a reminder once the date above is older than
that. A clean Homebrew install uses the current casks, while Company Portal or
another approved owner controls its own update schedule.

For a Homebrew-managed installation, check and apply a later update with:

```bash
brew update
brew outdated --cask 1password 1password-cli
brew upgrade --cask 1password 1password-cli
```

Do not replace a company-managed installation with Homebrew merely to obtain a
newer number. Follow the employer's update channel instead. Release notes are on
the [1Password stable release page](https://releases.1password.com/mac/stable/).

## Step 3.2 — Turn on the developer integrations

These two switches are what make the rest of the phase work: one lets `op`
commands talk to the desktop app, the other turns 1Password into your SSH agent.

In **1Password → Settings → Developer**:

1. Turn on **Integrate with 1Password CLI**.
2. Turn on **Use the SSH agent**.
3. If a vault list or allow-list is shown, allow the vault that will hold the
   development key.

Leave the desktop app open and unlocked for the rest of this phase.

Now verify the CLI integration from Terminal. The first command may raise a
Touch ID prompt — approve it:

```bash
op account list
```

```text
URL                 EMAIL                USER ID
my.1password.com    you@example.com      ABCDEFGHIJKLMNOPQRSTUVWXYZ
```

```bash
op vault list
```

```text
ID                            NAME
abcdefghijklmnopqrstuvwxyz    Personal
bcdefghijklmnopqrstuvwxyza    Development
```

Those values are illustrative; yours will differ. What matters is that both
commands return a table rather than an error.

If you instead see something like
`[ERROR] connecting to desktop app: not enabled`, the CLI integration is still
off — recheck switch 1 above and make sure 1Password is unlocked.

Do not put an account password or a service token in your shell profile. The
desktop integration is the stronger model and needs no stored secret.

## Step 3.3 — Set the SSH approval policy

This decides how often 1Password asks permission before an application may use
an SSH key. It applies to SSH-key use by Git, terminals, and IDEs — not to
browser autofill or `op` commands.

In **1Password → Settings → Developer**, expand the SSH Agent's advanced
settings and set:

```text
Ask approval for each new: Application and terminal session
Remember key approval: Until 1Password locks
```

That is the Day One Mac default. One approval covers the current application
and terminal tab, and locking 1Password clears it. It is deliberately stricter
than 1Password's own default, which approves per application only.

If an IDE's background Git fetches make that too noisy, use the application
scope with a 4-hour window instead. Avoid 12 hours, 24 hours, and
until-1Password-quits unless the Mac and application are trusted and you
deliberately want the longer window.

When a request appears, check the named application and key, confirm you started
a relevant Git or SSH action, then approve with Touch ID. Do not routinely
select **Approve for all applications**.

Every option, what each approval actually permits, how `op` CLI approval differs,
and how to change the policy later are in
[the 1Password SSH approval guide](../10-app-guides/1PASSWORD-SSH-APPROVAL.md). You do
not need it to finish this phase.

## Step 3.4 — GitHub setup

Complete shared Steps 3.0–3.3 first when using 1Password. Follow only this
provider section for Track 1; Track 3 also completes Step 3.5. For HTTPS
methods, use the GitHub choices in Step 3.6 instead of creating a key.

### Create or import a GitHub key — Create a new Ed25519 key for GitHub

Use this path for Track 1 or the GitHub account on Track 3.

1. Open and unlock 1Password.
2. Select the vault for that GitHub identity.
3. Choose **New Item → SSH Key**.
4. Choose **Add Private Key → Generate a New Key**.
5. Select **Ed25519**, then generate the key.
6. Name it by provider, identity, and purpose, for example
   `GitHub — Personal — Authentication`.
7. Save it.

The item now shows a public key beginning `ssh-ed25519`, like this:

```text
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExampleExampleExampleExampleExampleExa
```

You will paste that value — and only that value — into GitHub in the registration steps below.

The equivalent optional CLI command is:

```bash
op item create \
  --category ssh \
  --ssh-generate-key ed25519 \
  --title "GitHub — Personal — Authentication"
```

Use the desktop path when the vault or account choice is not obvious.

### Import a trusted existing key

Import instead of generating only when the key is trusted, still
authorized, and must keep the same fingerprint. You import the **private**-key
file, not its `.pub` companion.

1. Find the existing private key and its matching public key. Do not print,
   copy, paste, or upload the private-key contents.
2. List the public-key files. Files ending in `.pub` are public and safe to
   fingerprint; the same name without `.pub` is the private key:

   ```bash
   find "$HOME/.ssh" -maxdepth 1 -type f -name '*.pub' -print
   ```

   ```text
   /Users/your-name/.ssh/id_ed25519.pub
   /Users/your-name/.ssh/id_rsa_azure.pub
   ```

3. Read the fingerprint of the key you intend to import. Replace the whole
   `<existing-key>` placeholder, angle brackets included:

   ```bash
   ssh-keygen -l -E sha256 -f "$HOME/.ssh/<existing-key>.pub"
   ```

   For an existing key:

   ```bash
   ssh-keygen -l -E sha256 -f "$HOME/.ssh/id_ed25519.pub"
   ```

   ```text
   256 SHA256:AbCdEf123456ExampleFingerprint you@example.com (ED25519)
   ```

   The first number is the key size, the `SHA256:` value is the fingerprint to
   compare later, and the type is in parentheses. Write the fingerprint down —
   you check it again in step 8.

   If no `.pub` file exists, do not guess or expose the private key. Import the
   private key and use the public key 1Password derives from it.

4. Confirm the key is acceptable:
   - **GitHub** — Ed25519 or a modern RSA key.
   - **1Password** supports Ed25519 and RSA 2048/3072/4096 private keys in
     OpenSSH, PKCS#1, or PKCS#8 format. It cannot import `.ppk` directly.
5. In 1Password choose **New Item → SSH Key → Add Private Key → Import a Key
   File**, then select the private-key file. Drag-and-drop also works.
6. If prompted, enter the old key's passphrase once so 1Password can decrypt and
   re-protect it.
7. Save the item in the correct personal or work vault.
8. Compare the fingerprint 1Password displays with the one from step 3. **Stop
   if they differ** — the private key and public key are not the same pair.

Because importing preserves the public key, a correct existing registration at
The provider normally does not need replacing. Confirm the fingerprint
and account in the registration instructions below rather than adding a duplicate.

Do not delete the original files yet. Finish the phase, confirm the provider
accepts the key in Phase 4, and keep a temporary encrypted backup first. Then
review whether other hosts, signing identities or recovery procedures still
depend on the disk copy. Retain it explicitly if needed, or use the approved
owner-specific retirement procedure once its dependencies and recovery plan
are resolved. Importing the same key into 1Password does not create a new
identity: revoking that public key at the provider also revokes its vault-backed
use. This playbook deliberately provides no automatic `rm` for private keys.

### Confirm the agent can see your key

Before telling a provider about the key, prove the agent is actually serving it.

```bash
export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
ssh-add -l
```

```text
256 SHA256:AbCdEf123456ExampleFingerprint GitHub — Personal — Authentication (ED25519)
```

One line per key the agent holds: size, fingerprint, the 1Password item title,
and the type. At least one line must appear, and Azure DevOps requires an `(RSA)` identity.

That `export` affects **this terminal tab only**. It is not the permanent setup —
that is the `IdentityAgent` line the runner adds to `~/.ssh/config` in Step 3.9.
You never need to add this export to a shell file.

If you see `The agent has no identities`:

1. Unlock 1Password.
2. Confirm **Use the SSH agent** is still on.
3. Confirm the item's type is **SSH Key**, not a secure note.
4. Confirm the key's vault is allowed by the agent.
5. Quit 1Password, reopen it, and run `ssh-add -l` again.

Keep this fingerprint visible — you compare it against the provider in the next
step.

### First: copy the public key

Both routes start the same way. In 1Password, open the SSH Key item you made in
this provider section and choose **Copy Public Key**. That puts the whole `ssh-ed25519 …` or
`ssh-rsa …` line on your clipboard.

To check what you copied before pasting it anywhere:

```bash
pbpaste
```

```text
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExampleExampleExampleExampleExampleExa
```

It must be **one line** starting with `ssh-ed25519` or `ssh-rsa`. If you see
`-----BEGIN OPENSSH PRIVATE KEY-----`, you copied the private key by mistake —
stop, clear your clipboard, and copy the public key instead.

You can also read it from the command line, which is useful in a script:

```bash
op read "op://<vault>/GitHub — Personal — Authentication/public key"
```

Replace `<vault>` with your vault name and the title with your item's. If
that field name does not resolve on your version, list the item's actual field
labels with `op item get "GitHub — Personal — Authentication"`.

### Add the key to GitHub manually

Use this for Tracks 1 and 3. Skip it entirely on Track 2.

1. Open GitHub **Settings → SSH and GPG keys**.
2. Choose **New SSH key**.
3. Fill in the two fields:
   - **Title** — something that identifies this Mac, because the list is shared
     across all your machines. `MacBook Pro — Day One Mac` is clearer than
     `id_ed25519`.
   - **Key type** — leave it as **Authentication Key**. (**Signing Key** is for
     signing commits, which this phase does not set up.)
4. Paste the public key into the **Key** box and choose **Add SSH key**.
5. GitHub may ask for your password or a 2FA code to confirm.
6. The key now appears in the list with its fingerprint:

   ```text
   MacBook Pro — Day One Mac
   SHA256:AbCdEf123456ExampleFingerprint
   Added on 20 Sep 2026
   ```

   **Confirm that fingerprint matches the one from the agent check above.** If it does not,
   you pasted a different key.
7. If your organization uses SSO, choose **Configure SSO** next to the key and
   authorize it for that organization. Without this, pushes to that
   organization fail even though the key is valid everywhere else.

If you imported a key in the import instructions above and it is already listed, compare
fingerprints rather than adding a duplicate.

### Add the key to GitHub with a script

Same outcome as browser registration, from the terminal. GitHub only.

`gh` is already installed by the Installation Centre, but it is not signed in
until Phase 4. The script-assisted route therefore needs two one-off preparations.

**1. Sign `gh` in.** This is Phase 4 Step 4.4 brought forward; doing it now is
safe and you will not need to repeat it. It is a browser flow and needs no SSH
key of its own:

```bash
gh auth login --git-protocol ssh --web --skip-ssh-key
```

**2. Allow `gh` to manage keys.** Adding a key needs the `write:public_key`
scope, which the login above deliberately does not request:

```bash
gh auth refresh --hostname github.com --scopes write:public_key
```

That reopens the browser to approve the extra permission.

**3. Add the key.** With the public key still on your clipboard, pipe it
straight in — `-` tells `gh` to read the key from standard input, so nothing is
written to disk:

```bash
pbpaste | gh ssh-key add - \
  --title "MacBook Pro — Day One Mac" \
  --type authentication
```

```text
✓ Public key added to your account
```

`--type authentication` is the default; naming it makes the intent explicit and
avoids accidentally adding a signing key. If you already saved the key as a file
in Step 3.7, pass that path instead of `-`:

```bash
gh ssh-key add ~/.ssh/github-auth.pub \
  --title "MacBook Pro — Day One Mac" \
  --type authentication
```

**4. Confirm it landed:**

```bash
gh ssh-key list
```

```text
TITLE                        ID        KEY                          TYPE            ADDED
MacBook Pro — Day One Mac    12345678  ssh-ed25519 AAAAC3NzaC1...   authentication  1m
```

SSO still has to be authorized in the browser — `gh` cannot do that for you. If
your organization uses SSO, follow step 7 of the browser instructions above.

### Pin and test the github key

For the script-assisted 1Password route, run:

```bash
day-one-mac ssh-pin github
```

For the manual route, copy this item's **public** key, then run:

```bash
mkdir -p ~/.ssh
pbpaste > ~/.ssh/github-auth.pub
chmod 700 ~/.ssh
chmod 644 ~/.ssh/github-auth.pub
ssh-keygen -l -E sha256 -f ~/.ssh/github-auth.pub
```

The fingerprint must match the agent and provider registration. Use this
public file as `IdentityFile`, the 1Password socket as `IdentityAgent`, and
`IdentitiesOnly yes` in the matching Host block in `~/.ssh/config`. The
script-assisted runner writes that block in Step 3.9. Keychain and external
users use their selected key or agent instead of a 1Password pin.

After that configuration, test:

```bash
ssh -T git@github.com
```

GitHub replies with `successfully authenticated`; it does not provide a shell.

## Step 3.5 — Azure DevOps setup 🏢

Complete shared Steps 3.0–3.3 first when using 1Password. Follow only this
provider section for Track 2; Track 3 also completes Step 3.4. For HTTPS
methods, use the Azure choices in Step 3.6 instead of creating a key.

### Create or import an Azure DevOps key — Create a new RSA key for Azure DevOps 🏢

Take this branch for Track 2, and for the Azure half of Track 3.

1. Open and unlock 1Password.
2. Select the approved work or development vault.
3. Choose **New Item → SSH Key**.
4. Choose **Add Private Key → Generate a New Key**.
5. Select **RSA** and **3072 bits**. Do not select Ed25519 — Azure DevOps will
   reject it.
6. Name it, for example `Azure DevOps — Work — Authentication`.
7. Save it.

Its public key begins `ssh-rsa`:

```text
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQExampleExampleExampleExampleExampleEx
```

The equivalent optional CLI command is:

```bash
op item create \
  --category ssh \
  --ssh-generate-key rsa3072 \
  --title "Azure DevOps — Work — Authentication"
```

`ssh-rsa` at the start describes the key *format*, not the signature algorithm.
Modern OpenSSH and Azure DevOps negotiate RSA-SHA2 signatures automatically. Do
not add `HostkeyAlgorithms +ssh-rsa` or `PubkeyAcceptedAlgorithms +ssh-rsa`
overrides for Azure DevOps Services — they weaken the connection.

### Import a trusted existing key

Import instead of generating only when the key is trusted, still
authorized, and must keep the same fingerprint. You import the **private**-key
file, not its `.pub` companion.

1. Find the existing private key and its matching public key. Do not print,
   copy, paste, or upload the private-key contents.
2. List the public-key files. Files ending in `.pub` are public and safe to
   fingerprint; the same name without `.pub` is the private key:

   ```bash
   find "$HOME/.ssh" -maxdepth 1 -type f -name '*.pub' -print
   ```

   ```text
   /Users/your-name/.ssh/id_ed25519.pub
   /Users/your-name/.ssh/id_rsa_azure.pub
   ```

3. Read the fingerprint of the key you intend to import. Replace the whole
   `<existing-key>` placeholder, angle brackets included:

   ```bash
   ssh-keygen -l -E sha256 -f "$HOME/.ssh/<existing-key>.pub"
   ```

   For an Azure key stored as `~/.ssh/id_rsa_azure.pub`:

   ```bash
   ssh-keygen -l -E sha256 -f "$HOME/.ssh/id_rsa_azure.pub"
   ```

   ```text
   3072 SHA256:ZyXwVu987654ExampleFingerprint work@example.com (RSA)
   ```

   The first number is the key size, the `SHA256:` value is the fingerprint to
   compare later, and the type is in parentheses. Write the fingerprint down —
   you check it again in step 8.

   If no `.pub` file exists, do not guess or expose the private key. Import the
   private key and use the public key 1Password derives from it.

4. Confirm the key is acceptable:
   - **Azure DevOps** — RSA only. Replace a DSA, ECDSA, or sub-2048-bit RSA key
     with a new RSA 3072-bit key from the generation instructions above instead of importing it.
   - **1Password** supports Ed25519 and RSA 2048/3072/4096 private keys in
     OpenSSH, PKCS#1, or PKCS#8 format. It cannot import `.ppk` directly.
5. In 1Password choose **New Item → SSH Key → Add Private Key → Import a Key
   File**, then select the private-key file. Drag-and-drop also works.
6. If prompted, enter the old key's passphrase once so 1Password can decrypt and
   re-protect it.
7. Save the item in the correct personal or work vault.
8. Compare the fingerprint 1Password displays with the one from step 3. **Stop
   if they differ** — the private key and public key are not the same pair.

Because importing preserves the public key, a correct existing registration at
The provider normally does not need replacing. Confirm the fingerprint
and account in the registration instructions below rather than adding a duplicate.

Do not delete the original files yet. Finish the phase, confirm the provider
accepts the key in Phase 4, and keep a temporary encrypted backup first. Then
review whether other hosts, signing identities or recovery procedures still
depend on the disk copy. Retain it explicitly if needed, or use the approved
owner-specific retirement procedure once its dependencies and recovery plan
are resolved. Importing the same key into 1Password does not create a new
identity: revoking that public key at the provider also revokes its vault-backed
use. This playbook deliberately provides no automatic `rm` for private keys.

### Confirm the agent can see your key

Before telling a provider about the key, prove the agent is actually serving it.

```bash
export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
ssh-add -l
```

```text
3072 SHA256:AbCdEf123456ExampleFingerprint Azure DevOps — Work — Authentication (RSA)
```

One line per key the agent holds: size, fingerprint, the 1Password item title,
and the type. At least one line must appear, and Azure DevOps requires an `(RSA)` identity.

That `export` affects **this terminal tab only**. It is not the permanent setup —
that is the `IdentityAgent` line the runner adds to `~/.ssh/config` in Step 3.9.
You never need to add this export to a shell file.

If you see `The agent has no identities`:

1. Unlock 1Password.
2. Confirm **Use the SSH agent** is still on.
3. Confirm the item's type is **SSH Key**, not a secure note.
4. Confirm the key's vault is allowed by the agent.
5. Quit 1Password, reopen it, and run `ssh-add -l` again.

Keep this fingerprint visible — you compare it against the provider in the next
step.

### First: copy the public key

Both routes start the same way. In 1Password, open the SSH Key item you made in
this provider section and choose **Copy Public Key**. That puts the whole `ssh-ed25519 …` or
`ssh-rsa …` line on your clipboard.

To check what you copied before pasting it anywhere:

```bash
pbpaste
```

```text
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQExampleExampleExampleExampleExampleEx
```

It must be **one line** starting with `ssh-ed25519` or `ssh-rsa`. If you see
`-----BEGIN OPENSSH PRIVATE KEY-----`, you copied the private key by mistake —
stop, clear your clipboard, and copy the public key instead.

You can also read it from the command line, which is useful in a script:

```bash
op read "op://<vault>/Azure DevOps — Work — Authentication/public key"
```

Replace `<vault>` with your vault name and the title with your item's. If
that field name does not resolve on your version, list the item's actual field
labels with `op item get "Azure DevOps — Work — Authentication"`.

### Add the key to Azure DevOps 🏢

Use this for Tracks 2 and 3. Skip it entirely on Track 1.

**Azure DevOps has no command-line route.** The Azure CLI and its `azure-devops`
extension provide no command for managing a user profile's SSH public keys, so
this one is manual whichever track you are on.

1. Open your Azure DevOps organization.
2. Open **User settings → SSH public keys**.
3. Choose **New Key**.
4. Fill in the two fields:
   - **Name** — identify the Mac, for example `MacBook Pro — Day One Mac`.
   - **Public Key Data** — paste the `ssh-rsa …` value.
5. Paste carefully: **no added line breaks and no trailing spaces.** Azure
   rejects a key that has been wrapped by an editor.
6. Choose **Add**, then confirm the listed SHA256 fingerprint matches the agent check above.
7. Note any organization-enforced expiry and diary its rotation date.

One profile key normally works across every organization using the same Azure
identity, so you rarely need to repeat this per organization.

### Pin and test the azure key

For the script-assisted 1Password route, run:

```bash
day-one-mac ssh-pin azure
```

For the manual route, copy this item's **public** key, then run:

```bash
mkdir -p ~/.ssh
pbpaste > ~/.ssh/azure-devops-auth.pub
chmod 700 ~/.ssh
chmod 644 ~/.ssh/azure-devops-auth.pub
ssh-keygen -l -E sha256 -f ~/.ssh/azure-devops-auth.pub
```

The fingerprint must match the agent and provider registration. Use this
public file as `IdentityFile`, the 1Password socket as `IdentityAgent`, and
`IdentitiesOnly yes` in the matching Host block in `~/.ssh/config`. The
script-assisted runner writes that block in Step 3.9. Keychain and external
users use their selected key or agent instead of a 1Password pin.

After that configuration, test:

```bash
ssh -T git@ssh.dev.azure.com
```

Azure replies with `Shell access is not supported`; that response confirms authentication.

## Step 3.6 — Track 4: none of the above

Choose Track 4 when your account, company policy, or mixed authentication needs
do not fit the three managed provider tracks. It keeps provider CLI sign-in
and SSH registration under your control. The required foundation still checks
FileVault and the chosen authentication mode. Use `--auth-mode https` when
you need no managed SSH agent. Choose local dotfiles protection unless you
also install the provider CLI needed to verify a private Git dotfiles remote.

Script-assisted selection:

```bash
day-one-mac setup --track 4 --auth-mode https
```

The manual route records Track 4 in your own notes. Pick one method per
repository below. Replace the example owner, organization, project and repo
names with the clone URL from the provider. For an existing clone, use
`git -C /path/to/repo pull --ff-only`; it uses the same transport and credentials
as `git clone`. Check `git remote -v` before changing authentication.

### GitHub repository access

| Method | Better choice when |
|---|---|
| Anonymous HTTPS | You only read public repositories |
| HTTPS with a PAT | Browser sign-in is unavailable or policy requires a scoped, expiring token |
| GitHub CLI over HTTPS | You want browser sign-in and an automatically configured credential helper |
| Git Credential Manager | You prefer browser authentication shared with other Git clients |
| SSH with 1Password | You already use its agent and want keys kept in the vault |
| SSH with Keychain | You want a passphrase-protected local key without a password manager |
| SSH with an external agent | Your company or hardware device owns the key |

**Public HTTPS:** no login is needed to clone public code; writing still needs
permission and authentication.

```bash
git clone https://github.com/OWNER/REPO.git
```

**HTTPS with a PAT:** create a fine-grained token with access to the repository
and the minimum Contents permission needed (read for pulling, write for
pushing). Complete organization approval/SSO when required. Run the HTTPS clone
above and enter your username and the PAT at Git's password prompt. Never put
the token in a URL, shell history or a repository file. To store it in the Mac
Keychain for GitHub only:

```bash
git config --global credential.https://github.com.helper osxkeychain
```

**GitHub CLI:** on the manual route install it with `brew install gh`; Track 4
also needs this explicit installation because it does not select provider tools.

```bash
gh auth login --hostname github.com --git-protocol https --web
gh auth setup-git
gh repo clone OWNER/REPO
```

`gh repo clone` delegates to Git. It can use SSH instead when `gh` is configured
for SSH, but you must first register the key as described below.

**Git Credential Manager:** the guided HTTPS route offers `--https-helper gcm`
in [Phase 4](04-core-tools-and-hosting.md#step-46--run-or-resume-the-phase),
with provider-scoped helpers and a separate Git repository access gate. For a
manual setup, install `brew install --cask git-credential-manager`,
run `git-credential-manager configure`, then run the HTTPS clone. Follow its
browser sign-in. Select one intended helper for this host; review existing
helpers with `git config --show-origin --get-all credential.helper` before
changing a company configuration.

**SSH:** use the complete GitHub key registration and test in Step 3.4. For
1Password, create/import the Ed25519 key there. For a local key with Keychain,
follow [Keychain SSH](../manual/keychain-ssh.md), including its passphrase and
`UseKeychain` setup. For an external agent, load its public identity and confirm
`ssh-add -l`; register that public key in GitHub Settings → SSH and GPG keys.
Confirm the fingerprint and SSO authorization, then clone:

```bash
git clone git@github.com:OWNER/REPO.git
```

See [GitHub HTTPS authentication](https://docs.github.com/en/get-started/git-basics/about-remote-repositories)
and [GitHub CLI authentication](https://cli.github.com/manual/gh_auth_login).

### Azure DevOps repository access 🏢

| Method | Better choice when |
|---|---|
| Anonymous HTTPS | You read an accessible public project |
| Git Credential Manager with Microsoft Entra ID | You want the preferred browser/MFA route without maintaining a PAT |
| HTTPS with a PAT | Policy permits tokens and browser/Entra authentication is unsuitable |
| Azure CLI with Entra authentication | You already use `az` to discover repos or obtain short-lived access |
| SSH with 1Password, Keychain or an external agent | You prefer keys or your company supplies an approved agent |

Copy the HTTPS URL from **Repos → Files → Clone**. For a public repository,
try it directly. For private code choose one of the methods below:

```bash
git clone https://dev.azure.com/ORG/PROJECT/_git/REPO
```

**Git Credential Manager:** install `brew install --cask git-credential-manager`
and run `git-credential-manager configure`. Clone with the HTTPS URL and follow
Microsoft browser authentication. GCM can obtain Microsoft Entra tokens and
store credentials securely; ordinary `az login` alone does not authenticate Git.

**PAT:** create a scoped, expiring token in **User settings → Personal access
tokens**, with Code read permission for pulling (read/write only if needed).
At Git's HTTPS password prompt enter the PAT; use a nonempty username. A
host-specific Keychain helper can retain it:

```bash
git config --global credential.https://dev.azure.com.helper osxkeychain
```

Do not use `credential.helper store`, embed tokens in URLs, or paste them into
tracked configuration. Expired/revoked tokens must be replaced in the helper.

**Azure CLI:** install `brew install --cask azure-cli` if missing, then:

```bash
az login
az extension add --name azure-devops
az repos show --organization https://dev.azure.com/ORG \
  --project PROJECT --repository REPO --query remoteUrl -o tsv
```

Clone the returned URL with GCM or the PAT prompt above. `az devops login`
authenticates the DevOps CLI with a PAT; it does not install a Git credential
helper. For direct short-lived Entra Git authentication, follow Microsoft's
[Azure CLI token procedure](https://learn.microsoft.com/en-us/azure/devops/repos/git/auth-overview?view=azure-devops).
Keep those tokens out of saved configuration and shell history.

**SSH:** Azure requires RSA. Follow the complete generation/import, registration,
pinning and test in Step 3.5 for 1Password. For Keychain use the RSA path in
[Keychain SSH](../manual/keychain-ssh.md). For an external agent, ensure
`ssh-add -l` lists the intended RSA identity, then add its public key in
**User settings → SSH public keys** and confirm the fingerprint. Clone:

```bash
git clone git@ssh.dev.azure.com:v3/ORG/PROJECT/REPO
```

See [Azure credential managers](https://learn.microsoft.com/en-us/azure/devops/repos/git/set-up-credential-managers?view=azure-devops)
and [Azure SSH authentication](https://learn.microsoft.com/en-us/azure/devops/repos/git/use-ssh-keys-to-authenticate?view=azure-devops).

### Other hosts and repository tools

No additional managed hosting provider exists in this codebase. For other
hosts, use their supplied HTTPS or SSH clone URL and approved authentication.
`ghq get --vcs git URL` and VS Code's **Git: Clone** use the same Git transport and helper;
they do not provide another authentication method. Choose ghq only when you
want its repository folder layout. Explicit `--vcs git` avoids ghq metadata
detection failures for Azure URLs. For persistent per-provider defaults, see
[Step 4.3](04-core-tools-and-hosting.md#step-43--configure-global-git-defaults).
Test one real clone or fetch before calling
your self-managed access complete, then continue to FileVault in Step 3.8.

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

The filenames matter — the runner looks for these exact names. These are public
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
| 1 — GitHub | `~/.ssh/github-auth.pub` |
| 2 — Azure DevOps | `~/.ssh/azure-devops-auth.pub` |
| 3 — both | both files |

On Track 3 that looks like:

```text
  ✓ saved the GitHub public key to /Users/your-name/.ssh/github-auth.pub
  ✓ saved the Azure DevOps public key to /Users/your-name/.ssh/azure-devops-auth.pub
```

To do one provider at a time — useful when only one key has changed — name it:

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

If you would rather not involve the CLI — or `op` is unavailable — open the SSH
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

Open **System Settings → Privacy & Security → FileVault** and turn it on. Store
the recovery key somewhere independent of this Mac — a secured account or a
printed emergency record. Do not save the only copy on the disk it protects.

```bash
fdesetup status
```

```text
FileVault is On.
```

Initial encryption continues in the background after that status appears; you do
not need to wait for it.

## Step 3.9 — Run the phase

Everything manual is done. Run the gate once:

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
`~/.ssh/id_ed25519` files — which 1Password mode deliberately never creates — so
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
- a symbolic-link config is never replaced indirectly — edit its source instead.

Declining the merge changes nothing and leaves the phase incomplete. The saved
original can be restored later by the Day One Mac rollback tool.

If you have already completed Phase 5, `~/.ssh/config` is managed by chezmoi. The
runner refreshes the chezmoi source for you and prints
`refreshed the chezmoi source for ~/.ssh/config`. If it reports that it could
not, run `chezmoi add ~/.ssh/config` yourself and check `chezmoi diff` —
otherwise a later `chezmoi apply` would revert these provider blocks.

File permissions should be:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/config
```

Do not run `chmod -R 600 ~/.ssh` — directories need execute permission. Do not
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
| Azure rejects an Ed25519 key | Same cause — Azure accepts RSA only |
| Azure fails while several agent keys are visible | Pin the Azure key with Step 3.7; Azure accepts the first key offered |
| An imported key shows a different fingerprint | Stop; the private key and expected public key are not the same pair |
| `gh ssh-key add` reports `HTTP 404` or a missing scope | Run `gh auth refresh --hostname github.com --scopes write:public_key`, then retry (Step 3.4) |
| `gh ssh-key add` reports `key is already in use` | The key is already registered — list it with `gh ssh-key list` and compare fingerprints instead of adding it twice |
| Azure DevOps rejects a pasted key | Re-copy it as one line; an editor-wrapped key with line breaks is invalid (Step 3.5) |
| Provider later reports `Permission denied (publickey)` | Confirm the exact public key is registered on that account, and that SSO is authorized for the organization |
| FileVault cannot be enabled | Confirm this is an administrator account and finish pending macOS updates |

## Phase 3 completion checklist 🚦

- [ ] The authentication mode in `day-one-mac --status` is the one you intended.
- [ ] **1password mode:** 1Password is signed in and recoverable.
- [ ] The ownership check reports 1Password and its CLI as ready, whether Homebrew or an approved external installer owns them.
- [ ] `op account list` returns a table, and the runner confirmed it.
- [ ] The 1Password SSH agent is enabled.
- [ ] SSH approval uses **Application and terminal session** plus **Until
      1Password locks**, or a consciously reviewed alternative from
      [the approval guide](../10-app-guides/1PASSWORD-SSH-APPROVAL.md).
- [ ] `ssh-add -l` lists at least one identity, and its fingerprint matches what
      the provider shows.
- [ ] GitHub uses Ed25519 or a reviewed modern RSA key; Azure DevOps uses RSA.
- [ ] The public key is registered with every provider the track requires —
      manually or with `gh ssh-key add` — and SSO is authorized where the
      organization needs it.
- [ ] `~/.ssh/config` contains the marked Day One Mac block for every selected provider.
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
