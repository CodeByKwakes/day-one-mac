# Upgrade and migration notes

Day One Mac now distributes documentation and portable AI skills. The optional
runtime, setup runner and runtime release pipeline are removed. This is an
architectural change, not an instruction to remove your developer tools.

- Existing manager installations: follow [migration](migration/from-scripted-setup.md)
  and the complete [removal procedure](migration/remove-legacy-manager.md).
- Installed skills: use the [scoped lifecycle commands](../setup/manual/ai/day-one-skills.md#update-and-remove).
- Offline readers: build a new [static export](reading-and-export.md).
- VS Code helper users: select a private backup directory explicitly; the helper
  no longer stores new backups under legacy manager state.

Historical CHANGELOG entries, plans and audits describe their dated versions.
A local branch is not a published GitHub skill revision. Review the actual remote
revision before installing or updating from GitHub.

<a id="upgrade-notes-for-earlier-installations"></a>
<a id="october-2026-project-reorganization"></a>
<a id="what-the-current-release-uses"></a>
<a id="accepted-compatibility-names"></a>
<a id="move-an-existing-mac-to-the-standalone-runtime"></a>
<a id="or-if-gnu-wget-with-https-support-is-already-installed"></a>
<a id="wget---https-only---secure-protocoltlsv1_2--o-installer"></a>
<a id="httpsgithubcomcodebykwakesday-one-macreleaseslatestdownloadinstall-day-one-mac"></a>
<a id="if-phase-5-stops-for-a-manual-merge"></a>
<a id="second-brain-compatibility-data"></a>
<a id="completion-check"></a>
<a id="runtime-and-phase-contract-upgrade"></a>
