[← Security setup](README.md) · [Keychain alternative](keychain-ssh.md)

# 1Password, SSH and hosting walkthrough

**Outcome:** the selected vault owns your private keys; SSH uses its agent;
provider access is tested without exporting a private key to disk.

## 1. Install, sign in and establish recovery

use your approved installer, or, when Homebrew
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
Follow the [approval policy below](#what-each-approval-covers)
to choose deliberate SSH approval scope and duration; CLI approvals are separate.
Agent configuration and eligible-key selection are documented by
[1Password](https://developer.1password.com/docs/ssh/agent/config/).

## 3. Create or select provider-compatible keys

In the app, create an **SSH Key** item in the intended vault, or import an
existing key through the trusted app UI only. Use a clear provider/identity title,
such as `GitHub - Personal - Authentication`. Day One Mac uses provider words in
item titles to propose public-key selection; ambiguous matches need your review.

- GitHub: use an Ed25519 key for a new setup.
- Azure DevOps: use RSA, at least 3072 bits for this project's new-key baseline.
- Work/personal identities: use separate keys when policy or revocation needs differ.

Do not delete an imported key's old secure copy until the new route and recovery
are verified. Existing-key migration is not permission to upload it to Git.

## 4. Route SSH to the agent

prepare the private configuration directory:

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

The skip option avoids asking the CLI to generate/upload another key. Browser login and SSH
repository authentication are separate checks.

## 6. Add signing only after authentication works

Use the [signing walkthrough](ssh-signing-and-recovery.md#verify-a-real-signature)
for a local test, then decide repository-specific versus global defaults. Do not
assume that creating an SSH Key item or enabling the agent signs commits.

**Recovery:** an empty agent can mean a locked app, ineligible vault/key, or wrong
socket. Check the selected account and the agent configuration before generating
replacement keys. A denied approval is not a reason to disable approval controls.
For lost devices or exposed keys, follow the shared rotation procedure.

## 1Password SSH approval policy

**Read this when** the default asks for approval too often, or not often enough,
or when you want to know exactly what one approval permits.

Choose the approval scope and duration below for your own risk and workflow.

## What each approval covers

These controls apply to **SSH-key use** by Git, terminals, IDEs, and Git GUI
applications. They do not control browser autofill or `op` CLI sessions - see
[1Password CLI approval is separate](#1password-cli-approval-is-separate) below.

Open **1Password → Settings → Developer** and expand the SSH Agent's advanced
settings.

**Ask approval for each new** - how widely one approval reaches:

| Scope | What one approval permits | When to use it |
|---|---|---|
| **Application** | One named application and its subprocesses may use one specific SSH key | When per-tab prompts become too frequent |
| **Application and terminal session** | One application and - for Terminal, Warp, or an IDE terminal - only the current tab | **Day One Mac default** |
| **Request** | Only the current Git or SSH request; the next one prompts again | One-time access or particularly sensitive work |

1Password's own default is the **Application** scope. Day One Mac recommends the
narrower application-and-terminal-session scope, so expect slightly more prompts
than a stock install.

**Remember key approval** - how long an approval survives:

| Choice | What ends the approval |
|---|---|
| **Until 1Password locks** | Locking 1Password clears remembered approvals - **Day One Mac default**, and also 1Password's own |
| **Until 1Password quits** | Quitting clears approvals and ends all agent sessions |
| **A set amount of time** | 4, 12, or 24 hours; the approval stays tied to that application and key for the period |

The duration control is unavailable with **Request**, because each approval is
already limited to one request. With a timed approval, locking 1Password stops
the key being used until you unlock, but the application/key pairing is still
remembered for the rest of the period. There are no custom durations such as
30 minutes.

> **Labels drift between releases.** These were checked against 1Password for
> Mac 8.12.36 and the current published documentation on 20 September 2026. The
> app may word them slightly differently - for example describing the scopes as
> "for each new application". Follow what your installed app shows, and use the
> official [SSH authorization guide](https://www.1password.dev/ssh/agent/authorization)
> rather than forcing an option to match this page.

## Approving a request safely

1Password has no static list where you pre-approve application names. Each
request is judged when it appears.

When a prompt appears, check three things before approving with Touch ID:

1. the **application** named is the one you are using;
2. the **SSH key** named is the one that provider expects;
3. you actually started a Git or SSH action just now.

If a prompt appears when you did nothing, deny it.

Do not routinely choose **Approve for all applications**. That temporarily lets
every process running as your macOS user use that key for the approval period.

`~/.config/1Password/ssh/agent.toml` is not an application allow-list either. It
controls which keys are offered and in what order.

To end access early: close the approved terminal tab (terminal-session scope),
quit the approved application (application scope), lock 1Password (until-locks),
or quit 1Password to end every agent session at once. IDE background requests
can be easy to miss - a badge on the 1Password menu-bar icon leads to
**SSH request waiting**.

## 1Password CLI approval is separate

Commands beginning with `op` use the desktop CLI integration, not the SSH agent
settings above. Changing the SSH policy does not change `op` behaviour.

On macOS, CLI approval is per 1Password account and per terminal session. It
expires after **10 minutes of inactivity**, refreshes whenever used, and has a
**hard 12-hour limit**. A new terminal tab normally needs its own approval, and
locking 1Password revokes existing CLI authorization. These intervals are fixed
and cannot be replaced by the SSH agent's 4-, 12-, or 24-hour choices.

See 1Password's
[CLI integration security model](https://www.1password.dev/cli/app-integration-security).

## Change the approval settings later

You can change the policy at any time without recreating keys, editing
`agent.toml`, or rerunning Day One Mac.

1. Finish or pause any Git operation in progress.
2. Open and unlock **1Password**.
3. Select your account or collection, then **Settings → Developer**.
4. Expand the SSH Agent's advanced settings.
5. Change **Ask approval for each new** and **Remember key approval** using the
   two tables above. Choosing **Request** removes the duration control, because
   every approval becomes one-time.
6. To make a *stricter* policy take effect cleanly, quit 1Password completely,
   reopen and unlock it, then close and reopen the affected terminal tab or
   application. Quitting clears every existing agent session, including
   approvals granted under the old policy.

### Prove the new policy is live

In a repository whose remote uses SSH, run a fetch that changes nothing locally:

```bash
git fetch --dry-run
```

The first run should raise a 1Password prompt naming your terminal and key:

```text
Authorize "Terminal" to use the SSH key
GitHub — Personal — Authentication
```

Approve it. The command itself prints nothing when the branch is already current
:  silence is success. Now run it a second time **in the same tab**:

```bash
git fetch --dry-run
```

What you should see:

| Policy | Second run |
|---|---|
| **Request** | Prompts again |
| **Application and terminal session** | No prompt in this tab; a *new* tab prompts once |
| **Application** | No prompt in any tab of that application |

If the second run prompts when you expected it not to, 1Password most likely
locked in between - that is the **Until 1Password locks** duration doing its job.

## Turning the integrations off

The SSH agent settings are global. The prompt then scopes each approval to the
application and key it names. You cannot give Warp a four-hour default while
making VS Code one-request-only; choose the stricter policy when applications
have different trust levels.

To stop using the SSH agent entirely, turn off **Use the SSH agent** only after
configuring another authentication method - otherwise SSH-backed Git fetches and
pushes fail immediately. If the 1Password `IdentityAgent` line is managed by
chezmoi, edit its source and review `chezmoi diff` before applying a replacement.

To stop `op` commands using the desktop app, separately turn off **Integrate
with 1Password CLI**. That does not disable the SSH agent. Test the selected CLI workflow again after changing this integration.

Do not switch to manual CLI session tokens merely to avoid biometric prompts;
the desktop integration provides the stronger process- and terminal-bound model.
