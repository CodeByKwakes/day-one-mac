[← Security setup](security.md) · [Keychain alternative](keychain-ssh.md)

# 1Password, SSH and hosting walkthrough

**Outcome:** the selected vault owns your private keys; SSH uses its agent;
provider access is tested without exporting a private key to disk.

## 1. Install, sign in and establish recovery

**Script-assisted:** choose `1password` authentication and complete the
Installation Centre. **Manual:** use your approved installer, or, when Homebrew
is the intended owner and neither component exists:

```bash
brew install --cask 1password 1password-cli
```

Do not replace a Company Portal or other valid installation with a second copy.
Open 1Password, sign into the intended account, unlock it, and confirm which
vault is appropriate for this identity. Configure account MFA and recovery using
the account's own instructions. Store recovery material outside this Mac; the
[Emergency Kit guide](https://support.1password.com/emergency-kit/) explains what
to preserve. An organisation-managed account may have a different recovery owner.

## 2. Enable the integrations you actually use

In 1Password's developer settings, enable the SSH agent and, for Day One Mac's
`1password` mode, integration with the 1Password CLI. Check locally:

```bash
op --version
op account list
op vault list
SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock" /usr/bin/ssh-add -l
```

The last command selects this agent for this invocation only. No identities
before creating a key is different from a missing socket. Vault names and account
metadata can be sensitive: do not copy these outputs into public reports.
Follow the [approval-policy reference](../10-app-guides/1PASSWORD-SSH-APPROVAL.md)
to choose deliberate SSH approval scope and duration; CLI approvals are separate.
Agent configuration and eligible-key selection are documented by
[1Password](https://developer.1password.com/docs/ssh/agent/config/).

## 3. Create or select provider-compatible keys

In the app, create an **SSH Key** item in the intended vault, or import an
existing key through the trusted app UI only. Use a clear provider/identity title,
such as `GitHub — Personal — Authentication`. Day One Mac uses provider words in
item titles to propose public-key selection; ambiguous matches need your review.

- GitHub: use an Ed25519 key for a new setup.
- Azure DevOps: use RSA, at least 3072 bits for this project's new-key baseline.
- Work/personal identities: use separate keys when policy or revocation needs differ.

Do not delete an imported key's old secure copy until the new route and recovery
are verified. Existing-key migration is not permission to upload it to Git.

## 4. Route SSH to the agent

**Script-assisted:** complete Phase 3's public-key selection and configuration.
It can save `github-auth.pub` and `azure-devops-auth.pub`, then use those as pins.
Review existing blocks rather than adding a second block below them.

**Manual:** prepare the private configuration directory:

```bash
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
```

Copy
only the selected **public key** from the app into a new `~/.ssh/github-auth.pub`
file using your editor. Verify its fingerprint:

```bash
/usr/bin/ssh-keygen -lf "$HOME/.ssh/github-auth.pub"
```

Merge this into `~/.ssh/config` using an editor; do not replace the whole file:

```sshconfig
Host github.com
    User git
    IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    IdentityFile ~/.ssh/github-auth.pub
    IdentitiesOnly yes
```

For Azure, use a separate `Host ssh.dev.azure.com` block with the same agent,
`User git`, and `IdentityFile ~/.ssh/azure-devops-auth.pub`. Only include a pin
that actually exists and matches the vault item. Here `IdentityFile` selects a
**public** key; the agent retains the private half. Keep provider-specific blocks
before broad `Host *` defaults, and inspect earlier included files for conflicts.
After saving the config, run `chmod 600 "$HOME/.ssh/config"`.

## 5. Register and verify access

Follow [provider registration and host verification](ssh-signing-and-recovery.md#register-public-keys-and-test-authentication).
Approve only a prompt from the expected terminal/client, for the intended key
and operation. Test again after locking/unlocking 1Password. GUI Git clients may
use another Git/SSH binary or environment; test the actual client you intend to use.

For a manual GitHub CLI session using SSH:

```bash
gh auth login --git-protocol ssh --web --skip-ssh-key
gh auth status
```

The skip option avoids asking the CLI to generate/upload another key. Phase 4
already handles this login in the script-assisted route. Browser login and SSH
repository authentication are separate checks.

## 6. Add signing only after authentication works

Use the [signing walkthrough](ssh-signing-and-recovery.md#verify-a-real-signature)
for a local test, then decide repository-specific versus global defaults. Do not
assume that creating an SSH Key item or enabling the agent signs commits.

**Recovery:** an empty agent can mean a locked app, ineligible vault/key, or wrong
socket. Check the selected account and the agent configuration before generating
replacement keys. A denied approval is not a reason to disable approval controls.
For lost devices or exposed keys, follow the shared rotation procedure.
