# Audit remediation implementation record

This record follows the [14 October 2026 audit](TECHNICAL-AUDIT-2026-10-14.md).
It distinguishes repository changes from evidence that must come from real
pilot Macs and the organization's policy owners. Validation used isolated
fixtures; no MDM tenant or published release was changed. Installing the updated
local runtime is separate from applying workstation setup or passing its gates.

## Implemented changes

| Findings | Repository changes | Remaining acceptance |
|---|---|---|
| F01 | Draft releases; immutable candidate resolution; candidate lint/validation; exact archive acceptance; provenance and candidate evidence; guarded publication and draft retry | Run the workflow in GitHub, including failed-candidate and retry cases |
| F02 | Exact live private-origin branch comparison with a bounded, noninteractive query | Actual provider authentication in a pilot |
| F03 | Shared remote formatter strips credential/query/fragment data before report output; private report creation | Rotate any previously exposed credentials and retain/dispose old reports under policy |
| F04 | JSONC parsing, duplicate/type rejection, default-file checks in Phases 7 and 8 | Effective profile/workspace/enterprise policy and GUI review |
| F05–F06 | Personal/managed selection; approved policy and device/account-bound evidence; managed preflight; local control probes; MDM preference ownership; unresolved controls block Phase 8 | Organization baseline approval, enrollment, standard account/elevation, token and recovery drills |
| F07 | Explicit local context; override/drift rejection; resource ownership; image digests and launch-spec records; resource limits; disposable-data acknowledgement | Real engine pilot and deliberate migration of pre-existing resources |
| F08 | Full fixture argument forwarding and failing-sentinel regression | Included in aggregate validation |
| F09 | Selection-aware audit and failed-probe handling | Covered by helper and selection fixtures |
| F10 | Shared current-fingerprint prerequisite used by optional apply/direct runners; fixtures generate real fingerprints | Existing users must revalidate changed required phases |
| F11 | Native app signature, Gatekeeper, architecture, team/version observations; optional publisher allowlist enforcement; distinct manual software acceptance | Administrator-owned publisher provenance, licenses, CLI approval and first launch |
| F12 | Private observed-version snapshot/comparison; container digests; explicit moving-version versus approved-baseline contract | Approve actual versions and patch refresh cadence; snapshot matching is not byte identity |
| F13 | Approved HTTPS endpoint checks without redirects, credentials or certificate bypass; network acceptance control | Corporate Wi-Fi, PAC, VPN, split DNS, certificate renewal and identity tests |
| F14 | Recovery attestation and data-class/RPO/RTO drill checklist; narrow staging contract retained | Actual workload restoration and recovery timings |
| F15 | Peripheral acceptance matrix and policy evidence | Test the required physical equipment |
| F16 | Platform dependency range; CI matrix for macOS 15/26; 96 read-only selection cases | Fresh-user runs, macOS 27 and actual managed/hardware coverage |
| F17 | Track/preset/account corrections, readiness reference, command help and pilot runbook | Maintainer/user walkthrough; keep the historical audit tied to its revision |
| F18 | Explicit shell benchmark with samples/p50/p95; resource limits and proposed pilot budgets; accessibility protocol | Record real workload, keyboard/VoiceOver and performance evidence |

## Compatibility and rollout

Required-phase fingerprints include the new implementation and selected policy.
Existing Phase 8 markers become stale and must be revalidated before optional
apply. This is deliberate; no old marker is silently upgraded into new evidence.
The managed policy example is unapproved and cannot certify a device as ready.
A personal setup now also needs current recovery evidence at final acceptance.

Existing Module 09 containers/volumes remain untouched when ownership or spec
checks reject them. Do not delete data or relabel resources merely to satisfy a
gate. Export, restore-test and migrate through a separate reviewed procedure.
Fixed-credential services are explicitly restricted to synthetic disposable data.

Candidate release failures leave a draft. A maintainer can retry its tag using
the workflow's `draft_tag` input; the same candidate is fully tested again before
publication. No release was created or uploaded during local implementation.

## Validation record

Validation date: 15 October 2026 (Europe/London). Validation covered the
implementation developed over revision `2c5712645e2f07702f968e8e9f7bdbb02ab35536`.
The archive below was a local test candidate, not a published release. A local
installation uses a distinct version label and retains the previous runtime
for rollback; its generated version/checksum metadata therefore differs from
the test archive while its implementation files remain the same.

| Check | Result and scope |
|---|---|
| Full project validation | `scripts/validate.sh` passed in one final combined run, including required/optional flows, recovery, runtime installation, shell integration and both second-brain modules |
| Shell/document lint | Passed: 137 shell scripts, 138 Markdown files, zero findings |
| Workflow syntax | `actionlint` passed |
| Selection matrix | All 96 read-only base plans passed, including private state paths with spaces/Unicode |
| New safety regressions | Passed: fixture invocation, remote redaction, live remote identity, JSONC settings, current prerequisites, enrollment refusal and audit probe failures |
| Workstation readiness | 11 focused tests passed, including stale/mismatched evidence, invalid policy, false approval claims and publisher mismatch |
| Packaged acceptance | Exact candidate archive passed installation, 15 capabilities, packaged helpers, plan/apply/check/resume, drift and bounded audit |
| Native recovery | All eight disposable APFS checks passed on arm64/macOS 26.7.1; fixture image detached |
| Patch integrity | `git diff --check` passed |

Both packaged acceptance and the native rehearsal used the runtime archive with
SHA-256:

```text
e83b040107b1d5ef9e04d911f87599d4e1109fea62b929ef81d3564dae3835f4
```

The native checks cover read-only planning/checking, the Phase 8 gate, mounted
copy and verification, missing-target resume, destination-conflict preservation,
source-drift refusal and unmounted-source refusal. They do not demonstrate
complete user-data, metadata or database recovery.

The regressions also confirm that browsing/cancelling the optional tool selector
remains available before completion, while saving/installing is blocked without
current prerequisites. The dashboard reports healthy legacy containers without
ownership evidence as requiring review. Fixtures isolate enrollment from the
host Mac and explicitly reject positive, failed or unrecognized enrollment
responses for personal setup.

Live MDM, identity, hardware, actual database engines and full onboarding remain
[pilot acceptance work](../04-operations/WORKSTATION-ACCEPTANCE.md); local fixtures
do not replace them. The GitHub publication workflow must still run in GitHub,
including draft-failure/retry scenarios. Its signed candidate-evidence asset
records the checked-out revision and archive hash alongside the workflow
attestation; see the [attestation action's contract](https://github.com/actions/attest).
