[← Installation Centre](INSTALLATION-CENTRE.md) · **Phase 3** · [Phase 4 →](04-core-tools-and-hosting.md)

# Phase 3 — Security, 1Password, and SSH

**Time:** 30–60 minutes · **Required:** everyone

## Outcome

Git can authenticate to the providers your track selected, and FileVault
protects the disk.

How Git authenticates is your choice — see [Step 3.0](#step-30--choose-how-git-authenticates).
In the default **1Password** mode, its CLI and SSH agent are enabled, the
providers know the public key, and **no new plaintext private SSH key is
written to `~/.ssh`**. That last guarantee holds in every mode except
`keychain`, which creates a passphrase-protected key file on purpose.

If an existing key is imported, its old disk copy is retained until
authentication has been tested and you deliberately archive or remove that
redundant copy.

> 🏢 **Company-policy note:** If policy prohibits 1Password, you do not have to
> stop. Choose another mode in Step 3.0. Do not install an unapproved
> credential tool to satisfy a gate.

## How to use this phase

Choose the authentication mode in Step 3.0 before following a branch.

- **Manual route:** use the matching branch in
  [Manual 3](../20-reference/NOTION-SETUP-GUIDE.md#manual-3--configure-git-authentication-and-filevault)
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
| 3.4 | Create (or import) your SSH key | 1Password |
| 3.5 | Confirm the agent can see the key | Terminal |
| 3.6 | Register the **public** key with your provider | Browser *or* Terminal |
| 3.7 | Pin a key to a provider — only if you need it | Terminal |
| 3.8 | Turn on FileVault | System Settings |
| 3.9 | Run the phase | Terminal |

Step 3.6 can be done in a browser or with the `gh` CLI; both methods are
documented and give the same result.

The Installation Centre already installed or accepted 1Password and its CLI.
Phase 3 configures them; it does not install anything. If a component is
missing, run `day-one-mac install` first.

**Never paste, upload, or print the private-key field.** Only public keys leave
1Password.

An **SSH agent** is a local service that proves your identity to Git without
copying the private key into `~/.ssh`. A **socket** is the local connection file
used to reach that service. More terms are defined in [GLOSSARY.md](../20-reference/GLOSSARY.md).

### The worked example used below

Steps 3.1–3.9 are written as one continuous walkthrough for the most common
case: **Track 1 (GitHub only), creating a brand-new key.** Every command shows
the output you should expect.

If you are on another track or reusing a key, follow the same spine and take
the marked branch when you reach it:

- **🏢 Azure DevOps** — take Step 3.4b instead of 3.4a, and Step 3.6c instead of 3.6a.
- **Track 3 (both)** — do 3.4a *and* 3.4b, then 3.6a (or 3.6b) *and* 3.6c, and Step 3.7.
- **Reusing an existing key** — take Step 3.4c instead of 3.4a/3.4b.

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
  prompts for a passphrase; the runner never sees it. It then adds the key to
  the macOS Keychain and writes `UseKeychain yes` into `~/.ssh/config`. You
  still register the public key with your provider (Step 3.6), using
  `~/.ssh/id_ed25519.pub` or `~/.ssh/id_rsa_azure.pub`.
- **`external`** — skip Steps 3.1–3.4 and 3.7. Load a key into your own agent so
  `ssh-add -l` lists it, then do Step 3.6. Day One Mac creates nothing and only
  checks an identity is available.
- **`https`** — skip all of Steps 3.1–3.7. Go straight to Step 3.8 (FileVault),
  then Phase 4 configures the credential helper.

**FileVault (Step 3.8) is required in every mode.**

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

## Step 3.4 — Create your SSH key

An SSH key has a **private** part, which never leaves 1Password, and a **public**
part, which you give to your hosting provider.

Pick the key type your track needs:

| Track | Create | Why |
|---|---|---|
| **1 — GitHub** | One **Ed25519** key (Step 3.4a) | GitHub supports Ed25519 and 1Password recommends it for modern services |
| **2 — Azure DevOps** 🏢 | One **RSA 3072-bit** key (Step 3.4b) | Azure DevOps accepts only RSA, and negotiates RSA-SHA2 signatures |
| **3 — both** | Both of the above | A compromise or account change stays contained to one provider |

If Track 3 uses one identity and one trust boundary for both services, a single
RSA 3072-bit key can be registered with both. Separate keys are recommended when
GitHub is personal and Azure DevOps is work-managed. Never import an
employer-owned private key into a personal vault without explicit approval.

### Step 3.4a — Create a new Ed25519 key for GitHub

This is the spine of the walkthrough. Use it for Track 1, and for the GitHub
half of Track 3.

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

You will paste that value — and only that value — into GitHub in Step 3.6.

The equivalent optional CLI command is:

```bash
op item create \
  --category ssh \
  --ssh-generate-key ed25519 \
  --title "GitHub — Personal — Authentication"
```

Use the desktop path when the vault or account choice is not obvious.

### Step 3.4b — Create a new RSA key for Azure DevOps 🏢

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

### Step 3.4c — Import an existing GitHub or Azure key

Take this branch instead of 3.4a/3.4b only when the key is trusted, still
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

   For a GitHub key stored as `~/.ssh/id_ed25519.pub`:

   ```bash
   ssh-keygen -l -E sha256 -f "$HOME/.ssh/id_ed25519.pub"
   ```

   ```text
   256 SHA256:AbCdEf123456ExampleFingerprint you@example.com (ED25519)
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
   - **GitHub** — Ed25519 or a modern RSA key.
   - **Azure DevOps** — RSA only. Replace a DSA, ECDSA, or sub-2048-bit RSA key
     with a new RSA 3072-bit key from Step 3.4b instead of importing it.
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
GitHub or Azure DevOps normally does not need replacing. Confirm the fingerprint
and account in Step 3.6 rather than adding a duplicate.

Do not delete the original files yet. Finish the phase, confirm the provider
accepts the key in Phase 4, and keep a temporary encrypted backup first. After
that, use 1Password Developer Watchtower to remove the redundant on-disk private
key. This playbook deliberately provides no automatic `rm` for private keys.

## Step 3.5 — Confirm the agent can see your key

Before telling a provider about the key, prove the agent is actually serving it.

```bash
export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
ssh-add -l
```

```text
256 SHA256:AbCdEf123456ExampleFingerprint GitHub — Personal — Authentication (ED25519)
```

One line per key the agent holds: size, fingerprint, the 1Password item title,
and the type. At least one line must appear, and on Track 2 or 3 at least one
must say `(RSA)`.

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

## Step 3.6 — Register the public key with your provider

Creating the key put it in 1Password. This step tells your hosting provider
about it, so it will accept you. Only the **public** key is ever sent.

There are two routes. They produce exactly the same result, so pick one:

| Route | Use it when |
|---|---|
| **Manual** (3.6a / 3.6c) | The normal choice. Works for every provider, needs nothing installed |
| **GitHub CLI** (3.6b) | GitHub only, and you would rather not leave the terminal |

Azure DevOps has no script-assisted registration route — see 3.6c.

### First: copy the public key

Both routes start the same way. In 1Password, open the SSH Key item you made in
Step 3.4 and choose **Copy Public Key**. That puts the whole `ssh-ed25519 …` or
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

### Step 3.6a — Add the key to GitHub manually

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

   **Confirm that fingerprint matches the one from Step 3.5.** If it does not,
   you pasted a different key.
7. If your organization uses SSO, choose **Configure SSO** next to the key and
   authorize it for that organization. Without this, pushes to that
   organization fail even though the key is valid everywhere else.

If you imported a key in Step 3.4c and it is already listed, compare
fingerprints rather than adding a duplicate.

### Step 3.6b — Add the key to GitHub with a script

Same outcome as 3.6a, from the terminal. GitHub only.

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
your organization uses SSO, follow step 7 of 3.6a.

### Step 3.6c — Add the key to Azure DevOps 🏢

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
6. Choose **Add**, then confirm the listed SHA256 fingerprint matches Step 3.5.
7. Note any organization-enforced expiry and diary its rotation date.

One profile key normally works across every organization using the same Azure
identity, so you rarely need to repeat this per organization.

### Confirm the registration

Provider authentication is tested properly in Phase 4, but you can sanity-check
GitHub now if `gh` is signed in:

```bash
gh ssh-key list
```

For either provider, the check that matters is that the fingerprint shown in the
provider's web UI matches the one `ssh-add -l` printed in Step 3.5. A mismatch
means the key the agent offers is not the key the provider trusts, and Phase 4
will fail with `Permission denied (publickey)`.

## Step 3.7 — Pin provider keys when needed

**Skip this step if the agent holds exactly one key and you are on Track 1 or 2.**
Do it when you are on Track 3, when the agent holds several unrelated keys, or
whenever Azure DevOps is involved and more than one key is visible — Azure
accepts the first key offered and will not try a second.

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

It finds the item by matching your track against the SSH Key titles in
1Password, which is why the Step 3.4 naming convention matters. It refuses to
write anything it cannot confirm is a single-line public key, so a wrong field
or an ambiguous title stops with an explanation rather than putting the wrong
thing in `~/.ssh`:

```text
  ✗ Several 1Password SSH Key items match 'github':
  ⚠   GitHub work
  ⚠   GitHub personal
  ⚠ Rename them so only one matches this provider, or save the public key manually with Step 3.7.
```

Phase 3 also offers to do this for you when it notices a pin is missing, so you
may have already said yes there.

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

Every fingerprint must match the matching line from Step 3.5. Step 3.9 then adds an `IdentityFile` line
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
versions, checks that `op account list` really works, writes the SSH config,
lists the identities your agent offers, checks the key type suits your track,
and checks FileVault. A successful Track 1 run ends like this:

```text
  ℹ 1Password for Mac 8.12.36
  ℹ 1Password CLI 2.39.0
  ✓ 1Password CLI integration answers 'op account list'
  ℹ The SSH agent currently offers:
  ℹ   256 SHA256:AbCdEf123456ExampleFingerprint GitHub — Personal — Authentication (ED25519)
  ✓ 1Password SSH agent exposes at least one usable identity
  ✓ FileVault is on
  ✓ Git authentication (1password) and FileVault verified
```

Anything still manual returns a clear incomplete status with the next action,
rather than being marked successful.

Provider authentication itself is tested in Phase 4, once `gh` or `az` is
installed for your track.

### Reference — what the runner writes to `~/.ssh/config`

You do not edit this by hand. The runner maintains a marked, **track-specific**
block at the top of the file. Track 1 receives:

```sshconfig
# >>> Day One Mac: 1Password SSH agent >>>
Host github.com
    HostName github.com
    User git
    IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    ServerAliveInterval 60
    ServerAliveCountMax 3
# <<< Day One Mac: 1Password SSH agent <<<
```

If you completed Step 3.7, each host also gets its pin:

```sshconfig
    IdentityFile ~/.ssh/github-auth.pub
    IdentitiesOnly yes
```

`IdentitiesOnly yes` appears **only** next to an `IdentityFile`. On its own it
would restrict OpenSSH to the default `~/.ssh/id_rsa`, `~/.ssh/id_ecdsa`, and
`~/.ssh/id_ed25519` files — which this project deliberately never creates — so
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
| `ssh-add -l` cannot connect to an agent | Confirm `SSH_AUTH_SOCK` exactly matches the Group Containers socket in Step 3.5 |
| `The agent has no identities` | Work through the five checks in Step 3.5 |
| The runner says the agent offers no RSA identity | Azure DevOps needs RSA; create or import one with Step 3.4b or 3.4c |
| Azure rejects an Ed25519 key | Same cause — Azure accepts RSA only |
| Azure fails while several agent keys are visible | Pin the Azure key with Step 3.7; Azure accepts the first key offered |
| An imported key shows a different fingerprint | Stop; the private key and expected public key are not the same pair |
| `gh ssh-key add` reports `HTTP 404` or a missing scope | Run `gh auth refresh --hostname github.com --scopes write:public_key`, then retry (Step 3.6b) |
| `gh ssh-key add` reports `key is already in use` | The key is already registered — list it with `gh ssh-key list` and compare fingerprints instead of adding it twice |
| Azure DevOps rejects a pasted key | Re-copy it as one line; an editor-wrapped key with line breaks is invalid (Step 3.6c) |
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
- [ ] Track 3 keys — and Azure whenever several keys are visible — are pinned
      with public `IdentityFile` entries.
- [ ] **Except in keychain mode:** no plaintext `~/.ssh/id_*` private key
      exists. In keychain mode one is expected, and is passphrase-protected.
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
