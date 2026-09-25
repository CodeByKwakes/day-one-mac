# Set up a GitHub release automation token

Use this guide to give Release Please, or a similar GitHub Actions release
workflow, permission to create release pull requests, tags, and GitHub
Releases.

The examples are reusable. Replace `<owner>`, `<repository>`, and the secret
name with the values expected by your workflow. For Day One Mac, use:

```text
Repository: CodeByKwakes/day-one-mac
Secret name: RELEASE_PLEASE_TOKEN
```

## Understand what you are creating

The recommended setup for an individual maintainer is a fine-grained personal
access token restricted to one repository. Store that token as a GitHub Actions
repository secret.

This token is not:

- an SSH or deploy key used by `git push`;
- the automatically provided `GITHUB_TOKEN`;
- a password to store in the repository; or
- a value that should be printed in logs or shared in chat.

A separate token is useful because GitHub suppresses some follow-on workflow
runs for events created with the default `GITHUB_TOKEN`. A release pull request
created with the maintainer token can receive the repository's normal pull
request validation.

For an organisation or a repository with several maintainers, a GitHub App is
the stronger long-term choice because it is not tied to one person's account.
The fine-grained token route below is simpler for a single-maintainer project.

## Before you begin

You need:

- administrative access to the target repository;
- permission to create a fine-grained personal access token;
- access to the repository's Actions secrets; and
- the exact secret name referenced by the workflow.

Find the expected name in the workflow before creating the secret. For example:

```yaml
with:
  token: ${{ secrets.RELEASE_PLEASE_TOKEN }}
```

The secret name is case-sensitive.

## 1. Create a fine-grained personal access token

1. Sign in to GitHub with the maintainer account.
2. Open the profile menu and select **Settings**.
3. Select **Developer settings**.
4. Open **Personal access tokens**, then **Fine-grained tokens**.
5. Select **Generate new token**.
6. Enter a descriptive name, such as `<repository>-release-please`.
7. Add a description explaining that the token creates release pull requests,
   tags, and releases.
8. Select the repository owner as the **Resource owner**.
9. Choose an expiration that matches the project's rotation policy. A shorter
   lifetime reduces exposure but requires more frequent maintenance.
10. Under **Repository access**, select **Only select repositories**.
11. Select only the repository that runs the release workflow.

Do not grant access to every repository merely for convenience.

## 2. Assign repository permissions

Grant these repository permissions:

| Permission | Access | Purpose |
|---|---|---|
| **Contents** | Read and write | Create commits, version tags, and GitHub Releases |
| **Issues** | Read and write | Manage Release Please labels and related metadata |
| **Pull requests** | Read and write | Create and update the release pull request |
| **Metadata** | Read-only | Read basic repository information; GitHub includes this automatically |

Leave unrelated permissions set to **No access**. A release token should not
normally need administration, environments, deployments, secrets, or workflow
configuration permissions.

If the workflow must directly edit files under `.github/workflows`, reassess
that design before adding broader permissions. Release Please does not need to
edit workflow files for the standard release process.

## 3. Generate and capture the token

1. Review the selected owner, repository, expiry, and permissions.
2. Select **Generate token**.
3. Copy the token immediately; GitHub does not display it again.
4. Keep the browser page open until the repository secret has been saved.

Do not place the token in:

- a tracked or untracked project file;
- `.env` unless the file is both necessary and securely excluded;
- a shell-history command;
- a pull request, issue, or chat; or
- a screenshot or build log.

## 4. Store the token as an Actions secret

In the target GitHub repository:

1. Select **Settings**.
2. Select **Secrets and variables**, then **Actions**.
3. Select **New repository secret**.
4. Enter the exact secret name expected by the workflow.
5. Paste the token into the **Secret** field.
6. Select **Add secret**.

For Day One Mac, the name must be:

```text
RELEASE_PLEASE_TOKEN
```

You can also create or replace the secret with GitHub CLI. Omitting the value
from the command keeps it out of shell history:

```bash
gh secret set RELEASE_PLEASE_TOKEN --repo <owner>/<repository>
```

Paste the token only when the command prompts for it.

## 5. Verify the secret without exposing it

GitHub does not let you read a stored Actions secret. This is expected. Confirm
that the secret name exists:

```bash
gh secret list --repo <owner>/<repository>
```

For Day One Mac:

```bash
gh secret list --repo CodeByKwakes/day-one-mac
```

The output should include `RELEASE_PLEASE_TOKEN`. It will show metadata, not the
token value.

## 6. Test the release workflow

Use the repository's normal development workflow rather than making a dummy
release:

1. Merge a validated Conventional Commit into `main`.
2. Confirm the main-branch validation workflow succeeds.
3. Confirm the release workflow starts afterward.
4. Open the release workflow logs.
5. Confirm Release Please creates or updates its release pull request.
6. Confirm the release pull request receives the normal validation checks.

Do not merge the release pull request merely to test token access. Merge it only
when the proposed version and changelog are ready to publish.

For Day One Mac, a successful release pull request updates:

- `VERSION`;
- `CHANGELOG.md`; and
- `.release-please-manifest.json`.

After that pull request is merged, the release workflow creates the tag and
GitHub Release and attaches the verified runtime assets.

## Rotate the token

Rotate the token before it expires or immediately if it may have been exposed:

1. Create a replacement token with the same narrow repository access and
   permissions.
2. Replace the existing Actions secret with the new value.
3. Verify the secret name is still present.
4. Run or observe the next release workflow.
5. Revoke the old token after the replacement works.

To replace it with GitHub CLI:

```bash
gh secret set RELEASE_PLEASE_TOKEN --repo <owner>/<repository>
```

Set a calendar reminder before the expiry date. GitHub Actions will not renew a
personal access token automatically.

## Respond to an exposed token

Treat an accidentally displayed token as compromised even if it was visible
only briefly:

1. Revoke the token in GitHub immediately.
2. Generate a replacement with the minimum permissions.
3. Replace the Actions secret.
4. Review the repository's audit and workflow history for unexpected activity.
5. Remove the exposed value from logs, issues, or pull requests where possible.
6. If it entered Git history, follow the repository's incident process; merely
   deleting it in a later commit is not sufficient.

Never reuse the compromised value.

## Troubleshoot failures

### The workflow reports a bad credential

Confirm that the secret name in the workflow exactly matches the stored secret.
Then check whether the token expired, was revoked, or belongs to an account that
lost repository access.

### Release Please cannot create a pull request

Confirm that **Pull requests: Read and write** is enabled and that the token can
access the selected repository. Also check repository rules that restrict which
actors can create branches or pull requests.

### A tag or GitHub Release cannot be created

Confirm that **Contents: Read and write** is enabled. Check tag rulesets and
protected-tag policies for restrictions on the token owner.

### The release pull request does not run validation

Confirm that the workflow uses the stored maintainer token rather than the
default `GITHUB_TOKEN`. Also confirm that the validation workflow listens for
pull request events.

### The token requires organisation approval

An organisation can require approval for fine-grained tokens. Ask an
organisation owner to approve the token or use an approved GitHub App. Do not
replace the design with a broadly scoped classic token unless the repository's
security policy explicitly permits it.

## Completion checklist

- [ ] The token is limited to the intended repository.
- [ ] Only Contents, Issues, Pull requests, and required Metadata access are
      enabled.
- [ ] The repository secret name exactly matches the workflow.
- [ ] The token value is absent from files, history, logs, and chat.
- [ ] The release workflow can create or update its pull request.
- [ ] Pull requests created by release automation receive validation checks.
- [ ] A rotation reminder exists before the token expires.
