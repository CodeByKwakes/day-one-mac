# Contributor tooling

Use [CONTRIBUTING.md](../../CONTRIBUTING.md) for prerequisites and exact checks.
Tooling is a private pnpm package; it is not installed by users of the guides.

- ShellCheck checks maintained shell files.
- markdownlint checks documentation formatting.
- Static checks validate inventories, links, compatibility aliases and generated data.
- Integration fixtures exercise isolated skills, profile recovery and the reader.
- The pinned Skills CLI fixture verifies installation, update and removal in fake homes.
- Git hooks enforce Conventional Commits and run the relevant validation gates.

`tools/validate.sh --all` runs the local gate. CI also runs actionlint and the
Skills CLI acceptance. No runtime archive or installed-runtime test is needed.
Do not weaken a failing gate to hide a missing source or broken procedure.

<a id="set-up-contributor-linting-and-git-hooks"></a>
<a id="what-the-tooling-provides"></a>
<a id="hook-behaviour"></a>
<a id="prerequisites"></a>
<a id="1-install-the-locked-dependencies"></a>
<a id="2-verify-that-husky-is-active"></a>
<a id="3-test-the-commit-message-rules"></a>
<a id="4-run-the-linters-directly"></a>
<a id="5-use-the-hooks-during-normal-work"></a>
<a id="what-ci-enforces"></a>
<a id="bypass-a-hook-only-when-necessary"></a>
<a id="change-or-update-the-tooling"></a>
<a id="troubleshoot-setup"></a>
<a id="pnpm-install-cannot-find-node-or-pnpm"></a>
<a id="git-does-not-run-the-hooks"></a>
<a id="pnpm-reports-a-package-manager-version-mismatch"></a>
<a id="shellcheck-is-missing"></a>
<a id="markdown-lint-fails-on-an-intentional-format"></a>
<a id="a-valid-looking-commit-is-rejected"></a>
<a id="completion-checklist"></a>
<a id="runtime-changes-and-packaging"></a>
