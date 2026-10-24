[← Advanced 17](17-shell-and-package-automation.md) · **🤖 ⚙️ Advanced 18** · [Advanced 19 →](19-macos-gui-and-local-https.md)

# Advanced 18 - Hosting identities, Azure DevOps, and worktrees

**Time:** 45-120 minutes · **Required:** no · **Prerequisite:** required Phase 4

## Outcome

Repositories use your selected folder layout, with ghq only if opted in. Git
chooses the correct identity from the checkout path, selected hosting CLIs have explicit defaults,
and concurrent branch work uses safe Git worktrees without duplicating Git
history or secrets.

## Choose only the route you need

Azure Artifacts package access is separate from Git identities and SSH login.
If a project needs private npm packages, follow the optional
[manual Azure Artifacts guide](../../manual/git/azure-artifacts-npm.md). Module 18 does
not configure npm credentials or collect PATs.

### Executable identity and worktree review

The executable route creates a private review report and proposed Git
configuration fragments. It does **not** edit your Git configuration, create or
remove worktrees, sign commits, authenticate providers, or configure Azure.
Node 22+ and Git must already be on PATH; nothing is installed by this route.
Required Phase 8 must be complete before apply/resume.

Create a selection file with six tab-separated fields: `repository`, absolute
checkout root, expected name, expected email, signing policy (`ssh`, `openpgp`
or `off`), and the directory that should contain this repository's main and
linked checkouts. Replace the example paths and identity with your own:

```bash
umask 077
printf 'repository\t%s\t%s\t%s\t%s\t%s\n' \
  "$HOME/Developer/github.com/my-account/project" \
  'Your Name' 'you@example.com' ssh \
  "$HOME/Developer/github.com/my-account" > identities.tsv
day-one-mac advanced --module 18 --plan --manifest "$PWD/identities.tsv"
```

Keep the selection file private and outside public repositories; it contains
personal identity and local paths.

Add a row for every checkout whose effective identity you want checked,
including linked worktrees. A layout root is a boundary, not an identity rule:
Git's `includeIf gitdir` matches its administrative Git directory, which can
differ from a linked checkout's visible path. The report records both paths.

Review any `FAIL` results, then publish a snapshot and proposals:

```bash
day-one-mac advanced --module 18 --apply --manifest "$PWD/identities.tsv"
day-one-mac advanced --module 18 --check
```

Apply prints the artifact directory. Read `report.md`,
`identity-proposals.json`, and the numbered `identity-*.gitconfig` fragments.
Even a failed check produces diagnostic proposals, but apply exits nonzero
until the selected checks pass. Do not replace a complete configuration file
with a fragment; review the current owner and merge only intended settings.
Choosing `off` explicitly proposes disabling commit signing for that scope.

After manually correcting configuration or layout, preview again and capture
fresh evidence from the saved choices:

```bash
day-one-mac advanced --module 18 --plan
day-one-mac advanced --module 18 --resume
day-one-mac advanced --module 18 --check
```

Resume creates a new snapshot; previous reports remain available. Check detects
drift without accepting it. The layout gate rejects detached, missing, prunable
or out-of-boundary worktrees; a locked worktree is reported but not unlocked.
Signing checks verify configured policy, key presence and a readable SSH
allowed-signers file, **not** a successful signature or trust. Dirty files,
branch freshness, remote access and Azure defaults remain outside this check.
Continue with the selected manual routes below; automated success alone leaves
the dashboard `partial`.

This module contains two independent upgrades. They may be completed and
checked separately:

| Route | Read these steps | Choose it when |
|---|---|---|
| Multiple Git identities and hosting defaults | 18.1-18.5 | One Mac commits with more than one email or needs Azure defaults |
| Concurrent branch work with Git worktrees | 18.6 onward | You actively need two checked-out branches of one repository at the same time |

Completing the identity route does not require worktrees. Using worktrees does
not require a secondary email. Mark the whole advanced module complete only
after every route you chose has passed its own checks; leave the other route
explicitly recorded as not selected.

## Complete the shared manual actions

Follow the linked task for the selected actions, verify them, then return here. Manual configuration has one owner; the module records evidence.

| Manual action | Guide |
|---|---|
| 1. Confirm the selected track | [Open task](../../manual/git/multiple-identities.md#1-confirm-the-selected-track) |
| 2. Use a predictable ghq layout | [Open task](../../manual/git/multiple-identities.md#2-use-a-predictable-ghq-layout) |
| 3. Add a secondary identity only when needed | [Open task](../../manual/git/multiple-identities.md#3-add-a-secondary-identity-only-when-needed) |
| 4. Keep provider authentication separate | [Open task](../../manual/git/multiple-identities.md#4-keep-provider-authentication-separate) |
| 5. Verify signing and allowed signers | [Open task](../../manual/git/multiple-identities.md#5-verify-signing-and-allowed-signers) |
| 6. Add Azure repository and pipeline helpers 🏢 | [Open task](../../manual/git/multiple-identities.md#6-add-azure-repository-and-pipeline-helpers-) |
| 7. Understand worktree layout | [Open task](../../manual/git/multiple-identities.md#7-understand-worktree-layout) |
| 8. Handle ignored local files in worktrees | [Open task](../../manual/git/multiple-identities.md#8-handle-ignored-local-files-in-worktrees) |
| 9. Verify parallel work | [Open task](../../manual/git/multiple-identities.md#9-verify-parallel-work) |

## Advanced 18 completion checklist 🚦

- [ ] The chosen route(s) are recorded: identities/hosting, worktrees, or both.
- [ ] Any unselected route is explicitly recorded as not selected rather than
      mistaken for incomplete work.
- [ ] Real repository paths match the selected layout; ghq roots are checked only if ghq was selected.
- [ ] Each real repository resolves the correct email and configuration origin.
- [ ] Only selected-track CLIs and SSH hosts are required.
- [ ] Git authenticates through the selected method. If 1Password owns the keys, private keys remain in its vault; Keychain and external-agent users follow their selected key-storage rules.
- [ ] A disposable signed commit verifies correctly when signing is enabled.
- [ ] Azure defaults are explicit and private where applicable.
- [ ] Every worktree is listed by Git and has a clean/understood status.
- [ ] Ignored files are copied or generated narrowly, never wholesale.

```bash
day-one-mac advanced --complete 18
```

---

[← Advanced 17](17-shell-and-package-automation.md) · [Continue to Advanced 19 →](19-macos-gui-and-local-https.md)
