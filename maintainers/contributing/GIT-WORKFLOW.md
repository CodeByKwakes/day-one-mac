# Git workflow

1. Create a focused branch from the intended base and inspect existing changes.

   Expected result: unrelated work is preserved and the task scope is clear.

2. Make the owning source changes, regenerate skills and references, and run
   the checks in [CONTRIBUTING.md](../../CONTRIBUTING.md).

   Expected result: source and generated outputs agree; evidence is recorded.

3. Commit using Conventional Commits. State the concrete resulting behaviour
   and relevant tests in the body when the change needs explanation.

   Expected result: hooks accept the message and formatting. Do not bypass a
   failing check without identifying its cause and obtaining appropriate scope.

4. Push and open a pull request only when authorized. Review the complete diff
   and require the `validate` check before merge.

   Expected result: the reviewed revision becomes available for GitHub skill
   installation after publication to the chosen ref.

The runtime release workflow and Release Please configuration are removed.
There is no automatic runtime artifact publication. Existing tags and releases
are historical; optional future tags can identify reviewed skill snapshots.
After this change reaches the default branch, a repository administrator can
remove a dedicated obsolete release token after checking that nothing else uses it.

<a id="git-workflow-for-day-one-mac"></a>
<a id="workflow-at-a-glance"></a>
<a id="1-update-your-local-checkout"></a>
<a id="2-create-a-focused-branch"></a>
<a id="3-make-and-review-the-change"></a>
<a id="4-validate-locally"></a>
<a id="5-write-a-conventional-commit"></a>
<a id="6-push-and-open-a-pull-request"></a>
<a id="7-merge-the-pull-request"></a>
<a id="8-publish-a-release"></a>
<a id="release-lifecycle-and-failed-draft-retry"></a>
<a id="hotfixes"></a>
<a id="recommended-protection-for-main"></a>
<a id="recover-from-common-problems"></a>
<a id="the-branch-is-behind-main"></a>
<a id="validation-passes-locally-but-fails-in-github"></a>
<a id="release-please-does-not-open-a-pull-request"></a>
