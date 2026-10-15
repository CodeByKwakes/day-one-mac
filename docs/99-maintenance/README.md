[← Day One Mac home](../README.md) · **Maintainer material**

# Day One Mac maintenance records

This folder contains project-maintenance evidence rather than setup steps.

- [15 October documentation consistency audit](DOCUMENTATION-CONSISTENCY-AUDIT-2026-10-15.md)
  records baseline source/runtime differences, document contradictions and
  subsequent implementation status, with operational acceptance kept explicit.
- [25 September documentation audit](DOCUMENTATION-AUDIT.md) preserves the
  earlier clarity, alignment, accessibility and release-validation snapshot.
- [14 October technical audit](TECHNICAL-AUDIT-2026-10-14.md) and
  [implementation record](AUDIT-IMPLEMENTATION-2026-10-14.md) distinguish code
  remediation from managed-device, hardware and release pilot evidence.
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
