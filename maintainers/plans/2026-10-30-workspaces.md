# Developer workspace restoration implementation plan

Approved scope: a manual multi-display guide, optional Atticus guide and an
on-demand reviewed restore tool. VS Code stays maximized on the open MacBook.
Office has two external displays; Home has three through DisplayLink. Actual
resolutions and physical positions require local calibration.

## Constraints

- No live configuration, application installation, commit or push in this change.
- No background watcher, installed manager or mandatory source checkout.
- Private calibration and recovery data remain outside skill packages.
- Manual instructions use vendor interfaces without project helpers.
- App placement is requested through Raycast; final verification is human.

## Tasks

- [x] Add standalone Node.js helper and fixture tests for parsing, exact display
  identity, delayed displays, preview approval, recovery, locks and interrupted work.
- [x] Add manual workspace and optional Atticus guides, ownership links and
  existing app/shortcut skill routing. Document unverified hardware checks.
- [x] Update public inventories and regenerate portable skill packages.
- [x] Run repository gates and pinned Skills CLI acceptance; review the full diff.

## Review focus

DisplayLink readiness, duplicate monitor identities, multiple matching activities,
several VS Code windows, and interrupted restoration must stop or require an
explicit choice. Never infer a successful app layout from a successful URL open.

## Verification evidence

Lint, static checks, the macOS integration suite and actionlint passed.
Skills CLI 1.7.4 acceptance passed 66 isolated installations covering 11 skills,
three clients and two scopes, plus local Git update/removal cases. The cached
pinned CLI supplied the test executable; a fresh network download was unnecessary.
Fresh review found and resolved malformed-name coercion, failure recovery-path
reporting, snapshot overwrite and recovery-selector test coverage.

These are fixture results. DisplayLink, physical desk calibration, actual Raycast
window matching and Atticus build/provider access remain live acceptance work.
No applications, live preferences or installed skills were changed.
