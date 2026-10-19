# Git workflow for Day One Mac

Use this workflow when changing the Day One Mac source, documentation, tests,
or release automation. It keeps `main` releasable and gives Release Please the
commit information it needs to choose the next version.

## Workflow at a glance

```text
update main
    ↓
create a short-lived branch
    ↓
make and validate one focused change
    ↓
push the branch and open a pull request
    ↓
squash-merge after Validate passes
    ↓
Release Please updates its release pull request
    ↓
merge the release pull request when ready to publish
```

Do not develop directly on `main`. The only routine changes to `main` should
arrive through reviewed pull requests.

## 1. Update your local checkout

Start from the repository root. Switch to `main` and update it without creating
an accidental merge commit:

```bash
git switch main
git pull --ff-only origin main
```

If the pull fails because `main` contains local commits, stop and inspect them:

```bash
git status
git log --oneline --decorate --graph origin/main..main
```

Do not reset or discard those commits until you know whether they need to be
preserved.

## 2. Create a focused branch

Create one short-lived branch for one logical change:

```bash
git switch -c feat/descriptive-name
```

Use a prefix that describes the work:

| Prefix | Use it for |
|---|---|
| `feat/` | User-facing functionality |
| `fix/` | Defect corrections |
| `docs/` | Documentation-only changes |
| `ci/` | Continuous-integration and release automation |
| `chore/` | Maintenance that does not change user behaviour |
| `refactor/` | Structural changes without an intentional behaviour change |
| `test/` | Test-only changes |

Examples:

```text
feat/module-health-checks
fix/database-resume
docs/release-process
ci/action-pinning
```

## 3. Make and review the change

Keep unrelated work out of the branch. Before staging files, inspect the
working tree and the diff:

```bash
git status --short
git diff
```

Stage specific files rather than staging everything automatically:

```bash
git add path/to/file
git diff --staged
```

Never commit credentials, private keys, personal inventories, private
repository names, or absolute personal paths.

Install the shared contributor tools once per checkout. They validate commit
messages and run early lint checks through Git hooks:

```bash
pnpm install --frozen-lockfile
```

See [Set up contributor linting and Git hooks](CONTRIBUTOR-TOOLING.md) for the
prerequisites and exact hook behaviour.

## 4. Validate locally

Run the same core checks expected by continuous integration:

```bash
pnpm run lint
pnpm run validate:static
tools/validate.sh
git diff --check
git status --short
```

When release packaging changed, also build the release locally:

```bash
tools/build-release.sh
```

Fix validation failures before opening or updating the pull request.

## 5. Write a Conventional Commit

Release Please reads commit subjects on `main`. Use this format:

```text
<type>: <short imperative description>
```

Examples:

```bash
git commit -m "feat: add module health checks"
git commit -m "fix: resume interrupted database setup"
git commit -m "docs: clarify the chezmoi recovery process"
git commit -m "ci: validate release workflows"
```

The type controls the proposed release:

| Commit | Release effect |
|---|---|
| `fix:` | Patch, such as `1.0.7` to `1.0.8` |
| `feat:` | Minor, such as `1.0.7` to `1.1.0` |
| Breaking change | Major, such as `1.0.7` to `2.0.0` |
| `docs:`, `test:`, `chore:`, `ci:` | Normally no release by themselves |

Mark a breaking change explicitly:

```text
feat!: redesign the module configuration format

BREAKING CHANGE: Existing configuration files must be migrated.
```

## 6. Push and open a pull request

Push the branch:

```bash
git push -u origin feat/descriptive-name
```

Open a pull request in GitHub or with GitHub CLI:

```bash
gh pr create --fill
```

Give the pull request a Conventional Commit title, for example:

```text
feat: add module health checks
```

The title matters because a squash merge normally uses it as the resulting
commit subject on `main`.

Before merging, confirm that:

- the `Validate` workflow passes;
- the diff contains only the intended change;
- documentation reflects any behaviour change;
- review conversations are resolved; and
- no credentials or machine-specific private information are present.

## 7. Merge the pull request

Use **Squash and merge** for normal pull requests. Squashing produces one
coherent Conventional Commit on `main`, keeps history readable, and gives
Release Please predictable changelog input.

Delete the remote branch after merging. Then update your local checkout:

```bash
git switch main
git pull --ff-only origin main
git branch -d feat/descriptive-name
```

## 8. Publish a release

Normal contribution and release work are deliberately separate:

```text
feature pull request → main → Release Please pull request → release
```

After a successful validation run on `main`, Release Please creates or updates
one release pull request. That pull request collects the releasable commits and
updates:

- `VERSION`;
- the private contributor-tooling version in `package.json`;
- `CHANGELOG.md`; and
- `.release-please-manifest.json`.

Review and merge the release pull request when the accumulated changes are
ready to publish. The release workflow then creates the version tag and GitHub
draft release, validates the exact candidate, builds and tests its runtime
archive, attaches provenance/evidence and publishes only after those checks pass.

### Release lifecycle and failed-draft retry

1. Release Please creates the tag and a **draft** release after the release PR
   merges. A draft is not an available, validated public release.
2. The workflow resolves the tag to an immutable candidate commit, checks it out,
   and verifies tag, `VERSION`, checkout SHA and draft status agree.
3. Candidate dependency, workflow, lint and full validation checks run before
   building. Packaged acceptance tests the exact archive intended for upload.
4. `release-evidence.json` records candidate SHA, archive SHA-256 and run URL.
   Provenance attests the archive, installer and evidence; the workflow uploads
   those files plus the checksum while the release remains a draft.
5. The workflow rechecks tag identity and draft status, then publishes. Retain
   the successful run URL and matching evidence before announcing availability.

If any candidate step fails, inspect the failed run and keep the release a draft.
For a transient/tooling failure, run **Prepare and publish runtime release** on
`main` with **draft_tag** set to that existing draft tag. This skips release-PR
coordination and fully retests the same candidate; it does not bypass checks.
Leave **draft_tag** empty for normal release-PR coordination. Never reuse the
retry input for an already published release or move its tag to a code fix.
If the candidate code needs fixing, use a reviewed PR and a new release candidate
through the normal process; retain or retire the failed draft under maintainer
review. Do not publish incomplete assets manually.

Before adopting this workflow for production, a repository administrator must
rehearse successful publication, a failed candidate remaining draft and retry
against the same SHA. Local tests validate workflow structure and packaged code;
they do not prove GitHub permissions, attestations or live publication.

During normal development, do not manually:

- edit the version in `VERSION`, `package.json`, or
  `.release-please-manifest.json`;
- create a release tag;
- create a duplicate GitHub Release; or
- upload release assets by hand.

See [Set up a release automation token](../releasing/RELEASE-TOKEN-SETUP.md) if Release
Please cannot create or update its pull request.

## Hotfixes

Start an urgent fix from the latest `main`:

```bash
git switch main
git pull --ff-only origin main
git switch -c fix/urgent-problem
```

Use a `fix:` commit, open a pull request, and wait for validation. After the
pull request is squash-merged, Release Please adds the fix to the open release
pull request or creates a new patch release pull request.

If unreleased `feat:` commits are already on `main`, the next release can still
be a minor release. Do not bypass Release Please merely to force a patch number.

## Recommended protection for `main`

Follow the [recommended `main` protection checklist](../releasing/MAIN-PROTECTION-CHECKLIST.md)
to configure the GitHub ruleset in the correct order and verify it end to end.
The resulting ruleset:

- requires a pull request before merging;
- requires the `validate` GitHub Actions status check;
- requires review conversations to be resolved;
- blocks force pushes;
- blocks deletion; and
- permits squash merging.

For a single-maintainer repository, a required approval is optional. For a
multi-maintainer repository, require at least one approval. Continuous
integration remains authoritative in both cases.

## Recover from common problems

### The branch is behind `main`

Fetch and rebase before the branch is shared widely:

```bash
git fetch origin
git rebase origin/main
```

If the branch is already shared with other contributors, coordinate before
rewriting it. Prefer merging `origin/main` when rewriting shared history would
disrupt someone else's work.

### Validation passes locally but fails in GitHub

Open the failed `Validate` workflow, inspect the first failing step, and run
that command from the repository root. Check for macOS version differences,
missing validation tools, case-sensitive path errors, and files that were not
committed.

### Release Please does not open a pull request

Confirm that:

1. validation succeeded for a push to `main`;
2. the `Prepare and publish runtime release` workflow ran;
3. the repository contains a `RELEASE_PLEASE_TOKEN` Actions secret; and
4. the token has not expired or lost repository access.

Follow [the release-token setup guide](../releasing/RELEASE-TOKEN-SETUP.md) to create,
verify, or rotate the token.
