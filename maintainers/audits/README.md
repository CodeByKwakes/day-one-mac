[← Day One Mac home](../../docs/README.md) · **Maintainer material**

# Day One Mac maintenance records

This folder contains project-maintenance evidence rather than setup steps.

- [24 October manual setup audit](2026-10-24-manual-setup-audit.md) records
  findings, approved repairs, assistant design and acceptance limits.
- [24 October setup coverage inventory](2026-10-24-setup-coverage-inventory.md)
  records the 139 manual and assisted files scanned at the audit baseline.
- [15 October documentation consistency audit](DOCUMENTATION-CONSISTENCY-AUDIT-2026-10-15.md)
  records baseline source/runtime differences, document contradictions and
  subsequent implementation status, with operational acceptance kept explicit.
- [25 September documentation audit](DOCUMENTATION-AUDIT.md) preserves the
  earlier clarity, alignment, accessibility and release-validation snapshot.
- [14 October technical audit](TECHNICAL-AUDIT-2026-10-14.md) and
  [implementation record](AUDIT-IMPLEMENTATION-2026-10-14.md) distinguish code
  remediation from managed-device, hardware and release pilot evidence.
- [Acceptance procedure](../acceptance/ACCEPTANCE.md) covers packaged-runtime checks,
  disposable native restore testing and release-readiness reports.
- [Candidate release notes](../releasing/RELEASE-CANDIDATE.md) separate proposed changes,
  compatibility limits and evidence still required before publication.
- Executable structural and regression checks live in
  `../../tools/validate.sh`.
- ShellCheck policy lives in `../../.shellcheckrc` and is applied by
  `../../tools/lint.sh`.

Ordinary setup users do not need to read this folder.

---

[← Day One Mac home](../../docs/README.md)
