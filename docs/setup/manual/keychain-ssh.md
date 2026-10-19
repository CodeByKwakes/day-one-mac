[← Security setup](security.md) · [1Password alternative](1password.md)

# Apple Keychain-backed SSH walkthrough

**Outcome:** a passphrase-protected private key stays on disk; macOS Keychain
remembers its passphrase for Apple's SSH tools. This route does not need 1Password.

## 1. Inspect before creating anything

**Script-assisted:** select `keychain` authentication; Phase 3 creates or reuses
the provider key, checks passphrase protection and asks to load it. Do not also
run the manual creation commands below.

**Manual:** inspect existing `~/.ssh` files and configuration locally first.
If `id_ed25519` or `id_rsa_azure` already exists, decide whether it is the right
identity. Do not overwrite it or assume it is disposable. Public keys end in
`.pub`; the corresponding file without `.pub` is private.

## 2. Generate only the keys you need

For a fresh manual setup, create the directory if missing and set permissions:

```bash
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
```

Only if neither target file exists, generate the selected provider's key. Replace
the example comment with your chosen identity label; it is not a password:

```bash
# GitHub
/usr/bin/ssh-keygen -t ed25519 -C "developer@example.com" -f "$HOME/.ssh/id_ed25519"
# Azure DevOps, only if selected
/usr/bin/ssh-keygen -t rsa -b 3072 -C "developer@example.com" -f "$HOME/.ssh/id_rsa_azure"
```

At the passphrase prompts, enter **your own non-empty passphrase** and confirm it.
Typing is invisible. Do not type the literal words “non-empty passphrase”, press
Return twice for an empty one, or put the passphrase in command arguments.
If asked to overwrite a file, answer **no** and inspect the existing identity.

To add or change a passphrase on the selected existing key:

```bash
/usr/bin/ssh-keygen -p -f "$HOME/.ssh/id_ed25519"
```

Supply the old passphrase (Return only if it was empty), then your new non-empty
one. Substitute the Azure path only when that is the key being repaired. Changing
the passphrase does not change the public key. A forgotten passphrase cannot be
recovered from the encrypted file: use your secure recovery copy or replace/revoke
the key through the provider account.

## 3. Store the passphrase in Keychain

Run only for the key or keys you selected:

```bash
/usr/bin/ssh-add --apple-use-keychain "$HOME/.ssh/id_ed25519"
# Azure, if selected:
/usr/bin/ssh-add --apple-use-keychain "$HOME/.ssh/id_rsa_azure"
/usr/bin/ssh-add -l
```

Use Apple's `/usr/bin/ssh-add`, not a Homebrew replacement lacking Apple's option.
GitHub's [macOS key setup guide](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent?platform=mac)
describes that integration. If an old `SSH_AUTH_SOCK` override points at 1Password
or another agent, correct the shell configuration and open a new macOS terminal
session before retrying; do not globally delete every agent setting.

## 4. Configure the selected hosts

**Script-assisted:** inspect the Phase 3 provider blocks; do not duplicate them.
**Manual:** merge these into `~/.ssh/config` using an editor, retaining unrelated
hosts. Include only selected providers, before broad `Host *` defaults:

```sshconfig
Host github.com
    User git
    UseKeychain yes
    AddKeysToAgent yes
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes

Host ssh.dev.azure.com
    User git
    UseKeychain yes
    AddKeysToAgent yes
    IdentityFile ~/.ssh/id_rsa_azure
    IdentitiesOnly yes
```

After saving, set permissions only on files that exist for the selected route:

```bash
chmod 600 "$HOME/.ssh/config"
# GitHub private key, if selected:
chmod 600 "$HOME/.ssh/id_ed25519"
# Azure private key, if selected:
chmod 600 "$HOME/.ssh/id_rsa_azure"
```

Public `.pub` files may be mode `644`. Inspect effective routing with
`/usr/bin/ssh -G github.com` (substitute
Azure as needed). Check `identityfile` and `identityagent`; an inherited agent
override can defeat the intended route. `ssh -G` does not display Apple's
`UseKeychain` setting, so its absence in that output is not itself an error.

## 5. Register, test and preserve recovery

Use [provider registration](ssh-signing-and-recovery.md#register-public-keys-and-test-authentication)
with the relevant `.pub` file. Test again after logging out/in so a warm agent
session does not hide a setup issue. Add [signing](ssh-signing-and-recovery.md#verify-a-real-signature)
only when wanted, and test it separately.

Keep private keys out of chezmoi Git, even in a private repository. Choose either
an approved encrypted backup with recovery tested elsewhere, or a documented
provider-account recovery and key-replacement route. Saving the passphrase in
Keychain alone is not backing up the private-key file. Preserve the public
fingerprint and provider registration label as non-secret rotation references.
