[← Git workflow](GIT-WORKFLOW.md)

# Recommended `main` protection checklist

Use this checklist to protect `main` with a GitHub repository branch ruleset.
It is written for the maintainer of Day One Mac and matches the repository's
pull-request, validation, squash-merge, and Release Please workflow.

The recommended result is:

```text
topic branch → pull request → validate check → squash merge → main
                                                    ↓
                                   Release Please updates its release PR
```

## How to read this checklist

- Markdown boxes such as `- [ ]` track work you have completed.
- **Checked** means turn on that checkbox in GitHub.
- **Unchecked** means leave that checkbox off in GitHub.
- A setting described as a value or selection is not a checkbox.

GitHub may add rules that are not listed here. Leave new rules **Unchecked**
until the project has a documented reason to enable them.

## 1. Confirm the prerequisites

- [ ] Sign in to the GitHub account that administers
      `CodeByKwakes/day-one-mac`.
- [ ] Open the repository and select **Actions**.
- [ ] Confirm that the **Validate** workflow has completed successfully at
      least once. GitHub only offers recently reported checks when a required
      status check is selected.
- [ ] Confirm that the repository contains the Actions secret
      `RELEASE_PLEASE_TOKEN`. Follow
      [Release-token setup](RELEASE-TOKEN-SETUP.md) if it is missing.
- [ ] Confirm that there is no older branch protection rule or overlapping
      ruleset already targeting `main`. If one exists, compare its settings
      with this checklist before disabling or replacing it.

## 2. Configure the repository merge method

1. Open **Settings** in the repository.
2. Select **General**.
3. Scroll to **Pull Requests**.
4. Set the available merge methods as follows.

| GitHub option | State | Reason |
|---|---|---|
| Allow merge commits | **Unchecked** | Prevents merge commits from breaking the linear history requirement. |
| Allow squash merging | **Checked** | Produces one Conventional Commit on `main` for each pull request. |
| Allow rebase merging | **Unchecked** | Keeps the project workflow on one predictable merge method. |
| Always suggest updating pull request branches | **Checked** | Makes it easier to satisfy the strict up-to-date status-check rule. |
| Automatically delete head branches | **Checked** | Removes merged topic branches without affecting `main` or release tags. |

5. Under **Default commit message**, select **Pull request title and commit
   details**. The pull request title becomes the Conventional Commit subject
   used by Release Please.
6. Complete this section:

- [ ] The only enabled merge method is **squash merging**.
- [ ] The default squash commit message starts with the pull request title.

## 3. Create the branch ruleset

1. In repository **Settings**, select **Rules**, then **Rulesets**.
2. Select **New ruleset**, then **New branch ruleset**.
3. Enter these values:

   | Field | Value |
   |---|---|
   | Ruleset name | `Protect main` |
   | Enforcement status | **Active** |

4. Under **Bypass list**, add nobody. Release Please opens a pull request and
   does not need to bypass `main` protection.
5. Complete this section:

- [ ] The ruleset is named `Protect main`.
- [ ] Enforcement status is **Active**.
- [ ] The bypass list is empty.

## 4. Target only `main`

1. Under **Target branches**, select **Add a target**.
2. Select **Include by pattern**.
3. Enter `main` and save the target.
4. Do not add a branch exclusion.
5. Complete this section:

- [ ] The include pattern is exactly `main`.
- [ ] The ruleset does not target every branch.
- [ ] No exclusion allows `main` to escape the ruleset.

## 5. Set the branch rules

Configure the checkboxes under **Branch protections** in this order.

| GitHub option | State | Reason |
|---|---|---|
| Restrict creations | **Unchecked** | `main` already exists; this control is unnecessary for the project workflow. |
| Restrict updates | **Unchecked** | Enabling it would prevent normal pull-request merges unless a bypass actor were added. |
| Restrict deletions | **Checked** | Prevents accidental deletion of `main`. |
| Require linear history | **Checked** | Matches the repository's squash-only merge policy. |
| Require deployments to succeed before merging | **Unchecked** | This repository validates and publishes releases but has no required deployment environment. |
| Require signed commits | **Unchecked** | Do not enable until every maintainer and automation identity produces verified signatures. |
| Require a pull request before merging | **Checked** | Prevents normal direct pushes to `main`. |

### Pull-request requirements

After enabling **Require a pull request before merging**, configure its
additional options as follows.

| GitHub option | State or value | Reason |
|---|---|---|
| Required approvals | `0` for the current single-maintainer repository | CI remains mandatory without preventing the sole maintainer from merging. Use `1` when a second regular maintainer is available. |
| Dismiss stale pull request approvals when new commits are pushed | **Unchecked** | There are no required approvals in the current single-maintainer setup. |
| Require review from Code Owners | **Unchecked** | The repository does not currently depend on a `CODEOWNERS` review gate. |
| Require approval of the most recent reviewable push | **Unchecked** | With one maintainer, the author cannot provide the independent approval this option expects. |
| Require conversation resolution before merging | **Checked** | Ensures review discussions are resolved before merge. |
| Merge | **Unchecked** | Merge commits are not part of the project workflow. |
| Squash | **Checked** | Matches the configured repository merge method and Conventional Commit workflow. |
| Rebase | **Unchecked** | Keeps the accepted merge method unambiguous. |

### Required status check

1. Set **Require status checks to pass** to **Checked**.
2. Select **Add checks**.
3. Search for and select `validate` from **GitHub Actions**.

The workflow is displayed as **Validate**, but the required check is the job
name `validate` from `.github/workflows/validate.yml`. Do not require
**Prepare and publish runtime release**: it runs only after a successful push
to `main`, so requiring it on a pull request would create an impossible gate.

4. Configure the remaining status-check options:

| GitHub option | State | Reason |
|---|---|---|
| Require status checks to pass | **Checked** | Prevents merging when linting or validation fails. |
| Require branches to be up to date before merging | **Checked** | Tests the pull request against the latest protected `main`. |
| Do not require status checks on creation | **Unchecked** | There is no need to exempt creation of the existing `main` branch. |

5. Configure the remaining branch protection rules:

| GitHub option | State | Reason |
|---|---|---|
| Block force pushes | **Checked** | Prevents history from being rewritten on `main`. |
| Require code scanning results | **Unchecked** | Enable only after a code-scanning workflow reports a stable required result. |
| Require code quality results | **Unchecked** | Enable only after a code-quality integration is deliberately adopted. |
| Require merge queue | **Unchecked** | Adds unnecessary process for the current single-maintainer workflow. |

If GitHub does not show one of the unchecked options for this repository or
plan, continue without it.

6. Complete this section:

- [ ] Pull requests are required.
- [ ] The required status check is exactly `validate` from GitHub Actions.
- [ ] Pull request branches must be up to date before merging.
- [ ] Review conversations must be resolved.
- [ ] Linear history is required.
- [ ] Force pushes and deletion are blocked.
- [ ] No release workflow is configured as a pull-request status check.

## 6. Save and inspect the active ruleset

1. Review every setting once more before saving.
2. Select **Create**.
3. Return to **Settings** → **Rules** → **Rulesets**.
4. Open `Protect main` and confirm that its enforcement status is **Active**.
5. Open the repository's `main` branch and use the rules view to confirm that
   `Protect main` applies.

- [ ] The ruleset was created successfully.
- [ ] The ruleset is active and targets `main`.
- [ ] There is no overlapping rule that weakens or unexpectedly strengthens
      the intended policy.

## 7. Verify the protection with the next pull request

Use the next real documentation or code change; do not create a meaningless
commit solely to test the ruleset.

- [ ] Create a topic branch from the latest `main`.
- [ ] Open a pull request whose title follows Conventional Commits, such as
      `docs: clarify main protection`.
- [ ] Confirm the pull request cannot merge while `validate` is pending.
- [ ] Confirm `validate` passes.
- [ ] If GitHub reports that the branch is behind, update the branch and wait
      for `validate` to run again.
- [ ] Confirm unresolved review conversations prevent the merge.
- [ ] Resolve any conversations and select **Squash and merge**.
- [ ] Confirm the resulting commit appears on `main` without a merge commit.
- [ ] Confirm **Prepare and publish runtime release** runs after the successful
      **Validate** workflow on `main`.
- [ ] Confirm Release Please creates or updates its release pull request.

## 8. Follow the protected workflow from now on

After this ruleset is active, do not push ordinary work directly to `main`.
Use the workflow documented in [Git workflow](GIT-WORKFLOW.md):

```bash
git switch main
git pull --ff-only origin main
git switch -c docs/short-description

# Edit and validate the change, then commit and push the topic branch.
git push -u origin docs/short-description
```

Open a pull request, wait for `validate`, resolve conversations, and squash
merge. The Release Please pull request follows the same protected path.

## Recovery and maintenance

- If `validate` is not offered when adding a required check, run the
  **Validate** workflow successfully and reload the ruleset editor.
- If every pull request is permanently blocked, confirm that the required
  check is `validate`, not the workflow name or a release job.
- If Release Please cannot update its pull request, check
  `RELEASE_PLEASE_TOKEN`; do not add Release Please to the `main` bypass list.
- If an emergency change is required, use a short-lived topic branch and pull
  request. Temporarily disabling protection should be the last resort and must
  be reversed immediately after the incident.
- Review this checklist whenever validation job names, merge methods, GitHub
  plans, or repository ownership change.

## Final audit

- [ ] `main` is targeted by one active, understood ruleset.
- [ ] Direct updates require a pull request.
- [ ] The `validate` check is required and strict.
- [ ] Only squash merging is allowed.
- [ ] Force pushes and deletion are blocked.
- [ ] The single-maintainer approval count is `0`, or a multi-maintainer
      repository requires at least `1` approval.
- [ ] Release Please uses a pull request rather than bypassing protection.
- [ ] The full pull-request and release flow has been observed successfully.

## GitHub references

- [Creating rulesets for a repository](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/creating-rulesets-for-a-repository)
- [Available rules for rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets)
- [About protected branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
