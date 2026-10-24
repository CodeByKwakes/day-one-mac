# Configure HTTPS Git credentials

Use HTTPS when you do not want an SSH authentication key. Git Credential Manager
(GCM) or an approved existing helper stores credentials; never embed a token in
a clone URL, shell command or `.gitconfig`.

Complete [Git identity and provider CLI setup](../git/setup.md) first. Inspect
`git config --show-origin --get-all credential.helper` privately before changing
an existing helper. Preserve work/personal host scopes.

## 1. Select one helper

Choose GCM for its provider sign-in flow, or retain your organisation's approved
helper. GitHub CLI can supply GitHub credentials but does not authenticate Azure
Git. Azure CLI login also does not supply Git credentials.

Expected result: the chosen helper and its provider scope are recorded.

## 2. Configure the selected helper

For GCM, check `git-credential-manager --version`. If missing and Homebrew is the
approved owner, run `brew install --cask git-credential-manager`, then follow
GCM's [macOS configuration instructions](https://github.com/git-ecosystem/git-credential-manager/blob/main/docs/install.md).

For the GitHub CLI helper, run `gh auth setup-git` after the HTTPS login.
Do not run that command after choosing GCM unless deliberately changing owners.

Expected result: inspecting Git's credential helper shows the intended selection.
Keep organisation-provided configuration when policy owns it.

## 3. Preserve Azure repository scope

For Azure DevOps HTTPS, apply:

```bash
git config --global credential.https://dev.azure.com.useHttpPath true
```

Expected result: `git config --global credential.https://dev.azure.com.useHttpPath`
prints `true`. This distinguishes paths on the shared host; it does not create
credentials or choose an account.

## 4. Complete an interactive repository read

```bash
git -c credential.interactive=true ls-remote 'https://dev.azure.com/ORG/PROJECT/_git/REPO' HEAD
```

Replace the example with an authorised non-empty repository URL. Complete the
helper's browser/device prompt in your own session. Expected result: a commit
and `HEAD` reference. A public repository alone does not prove authentication.

## 5. Recheck from the intended IDE

Open the same repository in your Git client and perform its read/fetch operation.

Expected result: the same account has access. A GUI client may use another Git
executable or environment, so a terminal check is not the final client test.

## Troubleshooting and recovery

| Symptom | Action |
|---|---|
| `terminal prompts disabled` | Perform the interactive read above before retrying an automated check |
| Wrong account selected | Review the helper's host/path entry and sign-in scope; avoid clearing all Keychain items |
| Expired or revoked token | Renew through the provider and approved helper; do not add a token to the URL |
| Azure CLI passes but Git fails | Check GCM or the selected Git helper independently |

Restore only the previous helper configuration if changing it broke access.
Revoking a credential is a separate provider action. HTTPS authentication can
coexist with [SSH commit signing](ssh-signing-and-recovery.md).
