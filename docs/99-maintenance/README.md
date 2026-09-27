[← Day One Mac home](../README.md) · **Maintainer material**

# Day One Mac maintenance records

This folder contains project-maintenance evidence rather than setup steps.

- [Documentation audit](DOCUMENTATION-AUDIT.md) records the current clarity,
  alignment, accessibility, and release-validation result.
- [Acceptance procedure](ACCEPTANCE.md) covers packaged-runtime checks,
  disposable native restore testing and release-readiness reports.
- [Candidate release notes](RELEASE-CANDIDATE.md) separate proposed changes,
  compatibility limits and evidence still required before publication.
- Executable structural and regression checks live in
  `../../scripts/validate.sh`.
- ShellCheck policy lives in `../../.shellcheckrc` and is applied by
  `../../scripts/lint.sh`.

Ordinary setup users do not need to read this folder.

---

[← Day One Mac home](../README.md)
