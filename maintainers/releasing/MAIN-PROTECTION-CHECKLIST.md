# Main branch protection

Keep pull request review, Conventional Commit title validation and the `validate`
required check. The validation workflow runs supported macOS fixtures and skill
installation acceptance. No runtime release job is required.

After merging runtime removal, verify the default branch no longer contains
`.github/workflows/release.yml`. Old workflow runs and published releases remain
historical. Inspect consumers before removing a dedicated release secret; do
not delete a token shared by another workflow or repository.

Changing remote branch rules or secrets is an administrator action, separate
from this source change. This checklist does not claim those settings changed.

<a id="recommended-main-protection-checklist"></a>
<a id="how-to-read-this-checklist"></a>
<a id="1-confirm-the-prerequisites"></a>
<a id="2-configure-the-repository-merge-method"></a>
<a id="3-create-the-branch-ruleset"></a>
<a id="4-target-only-main"></a>
<a id="5-set-the-branch-rules"></a>
<a id="pull-request-requirements"></a>
<a id="required-status-check"></a>
<a id="6-save-and-inspect-the-active-ruleset"></a>
<a id="7-verify-the-protection-with-the-next-pull-request"></a>
<a id="8-follow-the-protected-workflow-from-now-on"></a>
<a id="edit-and-validate-the-change-then-commit-and-push-the-topic-branch"></a>
<a id="recovery-and-maintenance"></a>
<a id="run-release-automation-manually"></a>
<a id="resolve-common-protection-problems"></a>
<a id="final-audit"></a>
<a id="github-references"></a>
