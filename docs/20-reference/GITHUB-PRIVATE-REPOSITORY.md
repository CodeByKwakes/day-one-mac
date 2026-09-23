[← Start here](../START-HERE.md) · [Day One Mac home](../README.md) · [Begin Phase 1 →](../01-required/01-first-boot-and-decisions.md)

# Clone a private GitHub setup repository

Use this guide only when the repository you need at the beginning of Day One
Mac is private. A public repository clones over HTTPS without a username,
password, token, or SSH key.

A **fine-grained personal access token**, or PAT, is a temporary secret that
GitHub accepts in place of an account password for HTTPS Git operations. This
guide gives the token read-only access to one repository. It cannot push,
change settings, or access unrelated private repositories.

> 🔐 **Important:** GitHub account passwords do not work at a Git HTTPS
> password prompt. Never put a token directly in a clone URL or command because
> that can save the secret in shell history and Git configuration.

## Values to prepare

Replace these examples with the repository you are authorised to use:

| Placeholder | Meaning | Example |
|---|---|---|
| `<github-owner>` | Personal account or organisation that owns the repository | `example-user` |
| `<repository>` | Repository name without `.git` | `mac-setup` |
| `<device-name>` | Short label that identifies this Mac | `personal-macbook` |
| `<checkout>` | Final local checkout path | `~/Developer/github.com/example-user/mac-setup` |

For this repository, use the owner and repository shown in its GitHub URL.
Do not copy the example names literally.

## Step 1 — finish the Apple tools installation

On a clean Mac, request Apple's Command Line Tools:

```bash
xcode-select --install
```

Wait for the graphical installer to finish, then verify both tools:

```bash
xcode-select -p
git --version
```

The first command should print a developer-tools path. The second should print
a Git version instead of opening another installation prompt.

## Step 2 — open GitHub's token form

1. Sign in to the GitHub account that can read the private repository.
2. Open [New fine-grained personal access token](https://github.com/settings/personal-access-tokens/new).
3. Confirm that the browser address begins with `https://github.com/`.
4. Complete GitHub's password, passkey, authenticator, or GitHub Mobile check
   if requested.

GitHub's complete reference is
[Managing your personal access tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens).

## Step 3 — name and limit the token

Complete the form as follows:

| GitHub field | Recommended value |
|---|---|
| Token name | `Day One bootstrap - <device-name>` |
| Description | `Temporary read-only clone access for <repository>` |
| Resource owner | The `<github-owner>` account or organisation |
| Expiration | Seven days, or the shortest practical period |

If an organisation owns the repository, its security policy may require an
administrator to approve the token. Do not broaden the token to work around an
approval requirement; use the organisation's documented access process.

## Step 4 — select one repository

Under **Repository access**:

1. Select **Only select repositories**.
2. Open **Selected repositories**.
3. Select only `<github-owner>/<repository>`.

Do not select **All repositories** for a one-repository bootstrap token.

## Step 5 — grant read-only contents access

Under **Repository permissions**:

1. Find **Contents**.
2. Select **Read-only**.
3. Leave every other optional permission at **No access**.

GitHub adds **Metadata: Read-only** automatically. That is expected. The final
permissions should be:

- Contents: **Read-only**
- Metadata: **Read-only**
- All other optional permissions: **No access**

Read-only Contents permission is enough to clone, fetch, and pull. It cannot
push a commit.

## Step 6 — generate and protect the token

1. Review the resource owner, selected repository, expiration, and permissions.
2. Select **Generate token**.
3. Copy the complete `github_pat_...` value immediately; GitHub normally shows
   it only once.
4. If it must be retained briefly, save it as a temporary item in an approved
   password manager such as 1Password.

Never save the token in:

- a clone URL;
- shell history, a script, or an environment file;
- Git configuration;
- Notes, email, chat, or a screenshot;
- this repository or a dotfiles repository.

## Step 7 — clone the repository

Create its provider and owner folder, then clone it. Replace all angle-bracket
placeholders before running the commands:

```bash
mkdir -p "$HOME/Developer/github.com/<github-owner>"
git clone "https://github.com/<github-owner>/<repository>.git" \
  "$HOME/Developer/github.com/<github-owner>/<repository>"
```

At the prompts, enter:

```text
Username for 'https://github.com': <your-github-username>
Password for 'https://<your-github-username>@github.com': <paste the token>
```

The Terminal displays no dots, stars, or characters while the token is pasted.
That is normal. Press Return once after pasting.

Do not paste the account password. The word `Password` in this older Git prompt
means “authentication secret”; GitHub expects the token here.

## Step 8 — verify the checkout

Replace `<checkout>` with the actual absolute or `$HOME`-relative path:

```bash
cd "<checkout>"
git status --short --branch
git remote -v
```

The status should identify a branch without an authentication error. The remote
should use `https://github.com/<github-owner>/<repository>.git` and must not
contain the token.

For Day One Mac itself, enter its scripts directory and start the wizard:

```bash
cd "$(git rev-parse --show-toplevel)/day-one-mac/scripts"
./bootstrap-day-one-mac.sh --wizard
```

## Step 9 — move to SSH and revoke the token

After the security and hosting phases configure and verify the selected SSH
agent, change this repository from temporary HTTPS authentication to SSH:

```bash
cd "<checkout>"
ssh -T git@github.com
git remote set-url origin "git@github.com:<github-owner>/<repository>.git"
git fetch
```

The SSH test should identify the expected GitHub account, and `git fetch` must
finish without an authentication error.

Then remove the temporary credential:

1. Open [Fine-grained personal access tokens](https://github.com/settings/personal-access-tokens).
2. Open `Day One bootstrap - <device-name>`.
3. Select **Revoke** or **Delete** and confirm.
4. Delete any temporary password-manager item containing the token.

Revoking the HTTPS token does not affect the verified SSH remote.

## Troubleshooting

| Symptom | Meaning and safe response |
|---|---|
| `Password authentication is not supported` | An account password was entered. Retry and paste the token at the password prompt. |
| `Repository not found` | Confirm the URL, resource owner, selected repository, and that the signed-in account can access it. Private repositories may appear “not found” when access is missing. |
| Token works for another repository but not this one | Edit or replace it so **Only select repositories** includes the intended repository. |
| Clone works but push is denied | Expected for this read-only bootstrap token. Complete SSH setup before pushing. |
| The organisation shows approval pending | Stop and use its approval or company-support process. Do not create a broader classic token. |
| Git keeps using an old credential | Inspect the configured credential helper and remove only the obsolete GitHub entry; do not clear the complete macOS Keychain. |

If token creation is prohibited, download a repository archive while signed in
to GitHub and use it only as a temporary bootstrap copy. Replace it with a real
Git checkout once GitHub CLI or SSH authentication is available.

---

[← Start here](../START-HERE.md) · [Continue with Phase 1 →](../01-required/01-first-boot-and-decisions.md)
