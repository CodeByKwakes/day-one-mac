# Day One Mac — technical audit and implementation plan

**Audit date:** 14 October 2026, Europe/London  
**Reviewed revision:** `2c5712645e2f07702f968e8e9f7bdbb02ab35536`  
**Repository version:** `1.5.0`  
**Audience:** project maintainers, Mac administrators, security reviewers and technical onboarding owners  
**Document purpose:** explanation of readiness and risk, with a reference register of findings and an actionable remediation plan  
**Deployment scope:** both personal and organization-managed Apple-silicon Macs, as confirmed by the project owner

Implementation follow-up: [remediation record](AUDIT-IMPLEMENTATION-2026-10-14.md).
The findings below describe the reviewed revision, before remediation.

## Audit Findings

### Overall assessment

Day One Mac has a substantial, coherent foundation for an individual developer workstation. Its strongest engineering is in explicit ownership, reversible operations, separation of required and optional work, and selective recovery. It is not yet sufficient to certify a managed workstation as organizationally ready. Several verification paths also produce misleading success or failure results.

**Recommendation:** address the seven high-priority findings before presenting the project as a complete onboarding solution for managed Macs. Personal use should also receive the release, backup-verification, report-redaction and editor-check fixes. Continue to treat enterprise compliance, hardware compatibility and fresh-device operation as unverified until the acceptance plan below is completed.

This audit identifies **18 prioritized improvements: 7 high priority (P1) and 11 medium priority (P2)**. These include confirmed defects, implementation risks and requirements absent from the current product. They are not 18 demonstrated vulnerabilities. No P0 emergency or actual compromise was established.

The assessment does not claim that every application works flawlessly or that multiple Macs are identical. No fleet inventory, MDM tenant, organizational baseline, real account recovery drill or fresh-device eight-phase run was supplied. Repository-wide checks and targeted native tests establish useful evidence; they cannot establish those broader claims.

### Scope and method

The baseline inventory contains **427 tracked project files**, excluding local skill trees: **164 Markdown files, 131 `.sh` files, 41 test files**, two workflows and **355 runtime-manifest entries**. Shell source totals approximately **28,830 lines**, including tests and independent Second Brain components. Counts describe the reviewed revision, before this report was added.

Work performed:

1. Inventoried the repository, public command surface, phase/module catalogues, package manifest, CI workflows and documentation routes.
2. Traced the installer, dispatcher, required phases, state/fingerprint contracts, application ownership, optional modules, report generation, cleanup/rollback and backup/restore boundaries.
3. Reviewed security-sensitive branches manually and checked their surrounding tests.
4. Ran the repository validator, shell and Markdown lint, workflow lint, packaged acceptance and the omitted developer-folder fixture directly.
5. Ran native Module 20 acceptance using the project's own disposable APFS image, with successful detach.
6. Created disposable, local reproductions of five gate/report behaviors. No real credentials, personal configuration or production Docker resources were used.
7. Compared the deployment model against current Apple guidance and primary vendor documentation.

This is a repository-wide audit with risk-focused manual inspection, not a claim of exhaustive line-by-line verification or penetration testing of every third-party application.

### Evidence and test results

| Check | Observed result | What it establishes |
|---|---|---|
| ShellCheck 0.11.0, style severity | Passed, 133 shell entry points/scripts | No findings under the repository's configured exclusions |
| Markdown lint | Passed, 134 files in configured scope | Formatting consistency; excludes vault assets and other configured paths |
| GitHub Actions lint | Passed | Workflow syntax, not correctness of release authorization or commit selection |
| Full repository validator | Exit 1: one fixture blocked by sandbox socket permissions; all other checks passed | Structural and fixture coverage, subject to the skipped-test finding F08 |
| Affected secret-scan/SSH fixture, native retry | Passed | The socket-dependent fixture succeeds outside the restrictive sandbox |
| Developer-folder regression, invoked directly | Passed | The fixture omitted by the validator does work when actually invoked |
| Packaged-runtime acceptance | Passed | Archive install/verify; 15 capability entries; packaged Modules 17, 18, 20 and 21; drift and manual-boundary checks |
| Native APFS restore rehearsal | Passed; cleanup `detached` | Eight checks covering mounted copy, read-only inspection, prerequisite gate, missing-target resume, conflicts, source drift and unmounted-source refusal |
| Fresh-user required Phases 1–8 | Not run | Actual account, GUI, authentication, restart and onboarding readiness remain unproven |
| MDM, identity provider, corporate network and physical peripherals | Not exercised | Organization-specific acceptance remains open |
| Documentation reader | Export passed; source reviewed | Live rendering/VoiceOver/mobile interaction not verified; the browser tool blocked local-file URLs |

Native evidence used **macOS 26.7.1, arm64 and system Bash 3.2.57**. Contributor Node was **24.21.0**, pnpm **12.4.2**. These versions describe this test environment; they are not a new project compatibility promise.

The native candidate archive SHA-256 was:

```text
b7780e90ebb78a8e508772a58abcc738a39de25acb97f923914a1644b9d868ce
```

That identifies one locally built candidate, not the public GitHub release or a reproducible-build guarantee. Its archive was approximately **924 KiB**, and the offline HTML reader was approximately **2.2 MiB**.

Three read-only plans for a core, Python, Track 4, HTTPS, unmanaged selection took **0.084, 0.091 and 0.107 seconds**, median **0.091 seconds**. All returned valid JSON and created no state directory. This measures the lightweight planning path only; it does not measure installation, shell startup, application launch, battery use or large restores.

The aggregate validator is not recorded as an unqualified pass: its secret-scan/SSH fixture reached a Python Unix-socket bind that the sandbox refused. The same fixture passed in a targeted native retry. Separately, the developer-folder test was invoked directly because of F08. The initial contributor dependency fetch was blocked by sandbox networking; lint succeeded after a network-enabled retry.

### Assessment across the six requested dimensions

| Dimension | Assessment | Evidence and practical implication |
|---|---|---|
| Consistency | Partial | Shared catalogues, fingerprints and ownership are strong. Advanced audit, optional prerequisite checks and several overview documents diverge from the selection contract. |
| Correctness and functionality | Partial, with useful automated evidence | Package and native staging tests pass, but several gates can return misleading results. A complete new-user run remains necessary. |
| Security posture | Partial for personal use; incomplete for managed acceptance | FileVault, Gatekeeper and SSH protections exist. Managed enrollment, recovery escrow, account privilege and a complete security baseline are not acceptance gates. |
| Performance | Insufficient workload evidence | Lightweight planning is fast in this sample. No installation, shell, application, VM-memory or recovery budgets are defined. |
| UX | Strong structure, inconsistent promises | Resumable phases, previews and explicit manual steps are useful. Contradictory optionality and readiness semantics cause avoidable decisions and support work. |
| Maintainability and documentation | Substantial foundation; drift present | Runtime allowlist, tests and architecture reference help maintenance. Duplicated selection/gate logic and narrative catalogues are demonstrably out of sync. |

### Coverage of workstation components

| Component | Current project coverage | Missing acceptance evidence or capability |
|---|---|---|
| OS installation/reset | Delegates reset to Apple's UI; separates existing-Mac preparation and clean setup; checks native Apple silicon and developer tools | Managed enrollment sequence, approved OS build range, OS 27 native rehearsal, recovery/activation prerequisites by deployment type |
| Software deployment | Homebrew catalogue, external-app ownership, selected runtimes, editor and package inventory | Trusted publisher/version policy, exact environment snapshot, license entitlement and actual first-launch/upgrade checks |
| Security | FileVault/Gatekeeper checks, passphrase-aware SSH handling, strict host-key behavior, private state, reviewed changes | Enforced baseline, recovery escrow/unlock proof, SIP/startup policy evidence, lock/sharing rules, endpoint-agent health, privacy-permission ownership |
| User provisioning | Setup Assistant guidance, permanent account, Git identity and shell choices | Standard daily account plus managed administrator path, approved elevation, SSO/offboarding and secure/bootstrap-token evidence |
| MDM | Company Portal/external application route; Stage 0 enrollment-status inventory | First-class managed mode, policy ownership and blocking/readiness integration |
| Network | HTTPS downloads, provider access tests, local service port bindings | Wi-Fi/802.1X, proxy/PAC and TLS trust, VPN/split DNS, managed certificates, APNs/MDM reachability and expiration handling |
| Peripherals | Some user preferences and app guides | Dock/display/audio/camera/printer/security-key/backup-drive acceptance, firmware/driver compatibility and sleep/wake testing |
| Migration and recovery | Encrypted external APFS checks, scoped backups, checksums, stopped VM checks, staged restore and deliberate manual promotion | Application-level restoration, metadata-sensitive recovery, database restore integrity, backup schedule/retention and RPO/RTO evidence |
| AI, MCP and Second Brain | Optional client/artifact separation, manual trust/activation, Obsidian/Notion fixtures and Warp validation | Organization-approved services, data classifications, access scopes, account/GUI checks and external-provider service behavior |
| Maintenance/release | Allowlisted package, checksums, optional attestation, version history, CI and acceptance tooling | Exact-commit publication gate, consistent audit results, supported-version test matrix and retained release evidence |

For consistency, define uniformity against a **versioned role/deployment policy**, with explicit approved exceptions. Personal and corporate Macs should not be forced to install the same discretionary apps. Use Apple's supported enrollment and management mechanisms to apply organizational configuration; do not treat a cloned developer home directory as a fleet baseline. Apple's [Automated Device Enrollment guidance](https://support.apple.com/guide/deployment/automated-device-enrollment-management-dep73069dd57/web) describes enforcement of enrollment and minimum OS requirements.

### Strengths to preserve

- Eight required phases are separated from fifteen optional/advanced capability entries, including 10A. Manual trust, imports and account actions are generally identified explicitly.
- The standalone runtime uses an explicit file allowlist, checksums, exact inventory verification and versioned activation. Tests cover added files, corruption, symlinks and unsafe paths.
- State helpers provide atomic scalar writes, private file modes, path checks and operation locking. The architecture honestly documents same-user race and durability limits.
- Application ownership distinguishes Homebrew from external/App Store installations and avoids blindly reinstalling approved company software.
- SSH logic handles provider-specific identities, passphrase protection, bounded credential-tool calls and strict host-key verification without automatically accepting trust prompts.
- Stage 0 requires reviewed backup and restore steps before cleanup. It validates physical encrypted APFS storage and checks that selected container applications are stopped before VM-data copying.
- Module 20 rejects collisions and changed sources/destinations. Its native test passed. Its documentation explicitly excludes live promotion and metadata preservation.
- OmniRoute has stronger container controls worth reusing: explicit local context, digest-pinned image and owned-resource checks.
- The offline reader blocks network connections, escapes Markdown HTML, avoids remote images, and contains skip navigation, focus handling, accessible labels and status announcements. Terminal output supports plain/ASCII modes and includes real PTY regression tests.

## Improvement Recommendations

### Priority and impact model

**P1 — high:** resolve before broad managed rollout, or before relying on the affected safety claim. **P2 — medium:** resolve in the next implementation phases, before the corresponding capability is declared ready. A deployment gap is distinguished from an exploitable defect.

Effort estimates are **engineering person-days**, assuming an experienced Bash/macOS maintainer and existing test infrastructure. They include focused regression tests and documentation, but exclude procurement, MDM licensing and organizational approval delays. Impact is quantified using observable scope and failure conditions. No unsupported breach probabilities, speedup percentages or monetary losses are claimed.

| ID | Priority | Improvement | Evidence class | Effort |
|---|---|---|---|---:|
| F01 | P1 | Bind publication to validation of the exact release commit | Static workflow defect | 2–3 days |
| F02 | P1 | Verify the actual remote dotfiles branch | Reproduced false pass | 1–2 days |
| F03 | P1 | Redact credentials from repository URLs in reports | Reproduced sanitizer gap | 1–2 days |
| F04 | P1 | Parse effective VS Code approval settings | Reproduced false pass | 1–2 days |
| F05 | P1 | Introduce a managed-device/account provisioning contract | Scope/architecture gap | 5–8 days |
| F06 | P1 | Complete policy-driven security acceptance | Coverage gap | 3–5 days |
| F07 | P1 | Enforce local Docker endpoints and reviewed database ownership | Reproduced gate gap; other static risks | 2–4 days |
| F08 | P2 | Execute the omitted developer-folder fixture | Reproduced test-runner defect | 0.25–0.5 day |
| F09 | P2 | Make advanced audit selection-aware and fail closed | Static correctness defects | 1–2 days |
| F10 | P2 | Require current prerequisite evidence for optional apply | Static contract inconsistency | 0.5–1 day |
| F11 | P2 | Separate software presence, authenticity and policy approval | Trust-model gap | 2–4 days |
| F12 | P2 | Record reproducible versions and declared drift | Reproducibility gap | 2–4 days |
| F13 | P2 | Add managed-network diagnostics and ownership | Scope gap | 2–3 days |
| F14 | P2 | Extend recovery acceptance beyond byte staging | Evidence gap | 2–4 days |
| F15 | P2 | Add a peripheral/device acceptance matrix | Scope gap | 1–2 days |
| F16 | P2 | Test a declared OS/configuration support matrix | Test-coverage gap | 3–5 days |
| F17 | P2 | Reconcile documentation and onboarding decisions | Confirmed documentation drift | 2–3 days |
| F18 | P2 | Establish performance and usability budgets | Measurement gap | 1–2 days |

### F01 — Release publication is not bound to the validated commit

**Location:** [release workflow](../../.github/workflows/release.yml), lines 26–55; [validation workflow](../../.github/workflows/validate.yml).

The release job allows `workflow_dispatch` without a successful validation requirement. In the automatic path, it checks that a main-branch Validate run succeeded, then invokes Release Please and checks out the action's returned release SHA. There is no comparison with `workflow_run.head_sha` and no validation of that released SHA before building/uploading. Release Please creates the release before the build step.

**Impact:** every published runtime uses this workflow. A manual dispatch or overlapping main updates can break the promised connection between tested source and publication. This is a release-control defect; no defective release was shown to have been published. GitHub's [workflow event documentation](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows) and the [Release Please action](https://github.com/googleapis/release-please-action) explain the distinct trigger and release-selection behavior.

**Remediation:** separate release-PR maintenance from artifact publication. Resolve one candidate SHA, require all required checks on that SHA, build and test that candidate, then publish its exact artifacts and provenance. Apply the same rule to manual dispatch. Enforce the condition before creating a public release, or keep the candidate draft until gates pass.

**Acceptance:** simulate an older successful run with a newer unvalidated main head, failed checks and manual dispatch. None can publish. Retain candidate SHA, archive hash, validation run and attestation together.

### F02 — Dotfiles can be reported pushed when the remote branch is gone

**Location:** [Phase 8](../../src/setup/phases/08-verification.sh), lines 160–181.

The code runs `git ls-remote origin`, discards its output, then compares HEAD with the cached local `@{upstream}`. An accessible empty remote exits successfully; the cached tracking branch can still equal HEAD.

**Reproduction:** a disposable local bare repository was pushed, its remote branch was deleted, and the cached tracking ref was retained. The real function reported privacy, reachability and “branch pushed” as PASS with **zero actual remote refs**. Provider privacy and the displayed provider URL were stubbed; Git push, deletion, cached refs and remote enumeration were real local operations.

**Impact:** all private-Git dotfiles users can receive false recovery assurance under this condition. The affected commit may have no surviving remote copy, which matters before erase or cleanup.

**Remediation:** resolve the configured upstream remote/ref, query that exact remote ref with a deadline and noninteractive authentication, require it to exist, and compare its observed object ID with the intended local commit. If fetch-based analysis is needed, make that mutation explicit. Do not treat cached refs as live backup evidence.

**Acceptance:** deleted, force-pushed, renamed, unreachable and differently configured upstream branches fail or require review; an exact live match passes. Record observation time without credentials or raw remote output.

### F03 — Repository reports can retain credentials embedded in remote URLs

**Location:** [preflight report](../../src/preflight/preflight-audit.sh), lines 194–195 and 398–410; [advanced audit](../../src/modules/advanced-audit.sh), lines 142–146.

Both collect and write raw `git remote get-url origin` values. The preflight sanitizer removes tabs/newlines only. A synthetic `AUDIT_SENTINEL` password in a URL survived that exact sanitizer. The advanced report writes the remote directly.

**Impact:** a pre-existing token/password-bearing URL is copied into one or more report files, then potentially into backups or support material. Private file modes reduce access but do not remove the copied secret. No real credential was read or shown to have leaked during this audit. This contradicts the advanced command's claim that reports never print authentication tokens.

**Remediation:** use a shared URL formatter that strips userinfo, query strings and fragments, preserves only approved host/path metadata, and emits REVIEW for suspicious input. Redact before formatting, logging, exceptions or copying. Apply the same policy to other exported package/remote metadata.

**Acceptance:** synthetic credential-bearing HTTPS/SSH URLs, query parameters, encoded delimiters and malformed values never appear in Markdown, TSV, JSON, stdout or errors. Existing credential-free remotes remain useful. Document private retention and disposal of old reports.

### F04 — VS Code safety settings are checked as text, not configuration

**Location:** [Phase 7](../../src/setup/phases/07-editor.sh), lines 36–39; [Phase 8](../../src/setup/phases/08-verification.sh), editor checks around lines 418–420.

Two literal `grep` checks accept a JSONC comment containing `false` while the active setting is `true`. Both checks accepted a disposable example with exactly that structure. Valid alternative whitespace can also produce a false failure. Phase 8 checks the executable but does not independently verify these effective settings.

**Impact:** both approval controls can be misreported. These controls govern agent tool/terminal approval, so the consequence is more than cosmetic. The [VS Code approval documentation](https://code.visualstudio.com/docs/agents/run/approvals) confirms their purpose.

**Remediation:** parse JSONC with a supported parser; reject ambiguous duplicates and wrong types; evaluate the selected profile and relevant policy precedence. Distinguish user-file evidence from effective application configuration. For managed Macs, use supported [VS Code enterprise policies](https://code.visualstudio.com/docs/enterprise/policies). Recheck at final acceptance and report unobservable scopes as manual.

**Acceptance:** tests cover comments, whitespace, duplicates, missing values, true values, profiles and policy overrides. A file-content check alone must not claim every workspace is protected.

### F05 — Managed-device and least-privilege provisioning is not a first-class route

**Location:** [Phase 1 guide](../../docs/setup/assisted/01-first-boot-and-decisions.md), outcome and Steps 1.1–1.2; [Phase 1 implementation](../../src/setup/phases/01-decisions.sh); [preflight enrollment inventory](../../src/preflight/preflight-audit.sh), line 443; [application ownership](../../src/core/application-ownership.sh).

The main route assumes a permanent administrator account. Company Portal is supported as an application supplier, and Stage 0 can inventory enrollment, but there is no deployment-mode selection connecting MDM enrollment, standard-user operation, approved elevation, account provisioning and policy ownership. Hosting “work” tracks are not equivalent to device management.

**Impact:** every managed deployment lacks an explicit organizational readiness contract. Local choices can conflict with enforced policy, and the project cannot prove the intended account privilege or management state. This is a scope gap against the confirmed requirement, not proof that existing Macs are unmanaged.

**Remediation:** add personal/managed deployment modes. Define which authority owns OS updates, accounts, FileVault recovery, security agents, applications, certificates, login items and preferences. Managed mode should detect enrollment and wait for required management evidence before developer setup. Use standard daily accounts and a managed administrator/elevation mechanism according to policy; do not improvise account demotion or token changes.

Apple supports standard-user creation together with a managed administrator during enrollment: [local macOS accounts](https://support.apple.com/guide/deployment/set-up-local-macos-accounts-depca092ad96/web). Secure-token and volume ownership are distinct from administrator status: [Apple token guidance](https://support.apple.com/guide/deployment/use-secure-and-bootstrap-tokens-dep24dbdcf9e/web).

**Acceptance:** personal admin, managed standard-user and managed approved-elevation scenarios each have a tested path. Missing management evidence produces BLOCKED/REVIEW, not a guessed pass. MDM-owned settings are never overwritten by the local preference wizard.

### F06 — The security gate does not establish a complete workstation baseline

**Location:** [Phase 3](../../src/setup/phases/03-security.sh), lines 600–625; [Phase 8](../../src/setup/phases/08-verification.sh), lines 421–422; [optional preference security review](../../src/modules/configure-macos-settings.sh), lines 217–227.

FileVault and Gatekeeper are checked. Firewall state is displayed in a skippable settings flow, not enforced by the required completion gate. The required flow does not establish firewall exceptions, recovery-key custody/escrow, secure/bootstrap-token readiness, approved startup/SIP policy, lock timeout, remote-sharing posture or required endpoint-agent health. Phase 1's “fully updated” confirmation is not an OS-policy attestation.

**Impact:** a setup can complete without evidence for these controls. In particular, “FileVault On” proves neither organizational recovery-key availability nor a successful recovery procedure. Missing evidence must not be interpreted as disabled protection or a measured vulnerability.

**Remediation:** create a versioned control matrix with personal and managed applicability, expected state, authoritative owner, read-only probe, evidence timestamp, remediation guidance and approved exceptions. Include FileVault recovery, firewall/approved inbound services, Gatekeeper, SIP/startup posture, lock/sharing controls, update compliance and required security-agent health. Avoid automatically weakening protections to make tooling work.

Apple documents managed FileVault escrow and enablement separately from encryption status: [FileVault management](https://support.apple.com/guide/deployment/manage-filevault-with-device-management-dep0a2cb7686/web). Its [firewall payload](https://support.apple.com/guide/deployment/firewall-payload-settings-dep8d306275f/web) provides managed inbound rules; application firewall status is not outbound zero-trust enforcement. Organizational update policy should follow the approved rollout, supported by [Apple update management](https://support.apple.com/guide/deployment/install-and-enforce-software-updates-depd30715cbb/web).

**Acceptance:** every required control resolves to PASS, FAIL, MANUAL/UNKNOWN or an approved exception. No required UNKNOWN yields overall compliant/ready. Recovery custody is verified without exporting the key into evidence.

### F07 — The “local databases” module can operate against an unverified endpoint

**Location:** [database module](../../src/modules/configure-databases.sh), lines 19, 160–169, 257–339; compare [OmniRoute](../../src/modules/configure-omniroute.sh), lines 76–104.

The default `auto` runtime returns success from `verify_selected_context` without inspecting the context. Named Docker/OrbStack modes compare context names, not endpoint locality. Subsequent `docker` commands use the ambient endpoint. The gate was reproduced returning success without invoking any Docker inspection. No real remote Docker daemon was contacted.

Additional weaknesses in the same module: existing volumes/networks are accepted by name; container checks cover only part of the specification; three images use mutable tags; PostgreSQL/MongoDB use fixed development credentials and Redis has no configured authentication; no per-container CPU/memory budgets are set. Loopback binding is a useful defense but does not authenticate other processes or containers.

**Impact:** under an unexpected Docker context, creation/start operations can reach a different daemon than the user intended. Named-volume reuse can attach pre-existing data to a new service. Default credentials and unlimited resource use are unsuitable as a universal managed-workstation policy. Risk is conditional on selected databases and environment; there is no evidence of remote exposure in this session.

**Remediation:** reuse OmniRoute's explicit local endpoint and resource-identity pattern. Pin and persist the reviewed context, reject conflicting environment overrides, and use explicit context arguments on every call. Require owned resources or a deliberate adoption procedure; verify complete port, mount, network, image and privilege specifications. Support image digests, protected per-install credentials or an explicitly labelled disposable-data mode, and configurable resource limits.

**Acceptance:** SSH/TCP/ambiguous endpoints are refused for this local module; context drift and unowned volumes cannot be silently accepted. Test wrong passwords, unhealthy services, extra port mappings, privileged settings and restart behavior. Docker's [context documentation](https://docs.docker.com/engine/manage-resources/contexts/) describes how contexts select daemon endpoints.

### F08 — One validation success message does not run its regression test

**Location:** [validator](../../tools/validate.sh), lines 42–48 and 957–959.

`run_fixture` executes only its third argument. The developer-folder call passes `/bin/bash` as the third argument and the test path as the fourth. The result is an empty shell reading `/dev/null`, which exits successfully.

**Impact:** one named suite is omitted from every aggregate validation run. A deliberately failing sentinel was reported PASS without executing. The actual developer-folder test passed when invoked directly, so this is a coverage defect, not evidence that developer folders currently fail.

**Remediation:** either pass the executable script as the third argument or shift labels and invoke the full remaining argument vector. Keep shell arguments as an array, not evaluated text.

**Acceptance:** a failing sentinel executes and causes failure; a successful sentinel executes once. Confirm the folder fixture appears in the aggregate execution record, not just its success label.

### F09 — Advanced audit disagrees with supported choices and can hide probe failures

**Location:** [advanced audit](../../src/modules/advanced-audit.sh), lines 95–124; compare [configuration choices](../../src/core/configuration-choices.sh) and [Phase 7 core handling](../../src/setup/phases/07-editor.sh).

The audit always requires `chezmoi`, `starship` and `code`, even when the user selected unmanaged configuration, no prompt or the core preset. It also suppresses failed `brew outdated` and `chezmoi status` commands with `|| true`, interpreting empty output as a clean result.

**Impact:** valid minimal configurations can receive up to three irrelevant missing-tool failures. Conversely, at least two inspection paths can report PASS after a failed probe. This makes maintenance results unreliable and can pressure users to install tools they declined.

**Remediation:** derive required checks from the same selection contract as setup. Preserve exit status separately from output; classify failed inspection as UNKNOWN/FAIL. Apply deadlines and retain redacted diagnostics. Clearly distinguish inventory, local verification and live account checks.

**Acceptance:** core/unmanaged/no-prompt configurations produce no irrelevant failure. Stubbed failing probes never return clean PASS. Run the same policy fixtures against setup, advanced audit and the unified dashboard.

### F10 — Optional apply accepts obsolete Phase 8 completion

**Location:** [optional dispatcher](../../src/modules/optional-module.sh), line 127, and analogous guards in configuration runners; compare [architecture contract](../../docs/explanation/ARCHITECTURE-AND-STATE.md).

Required status computes fingerprints and identifies stale completion. Optional apply generally checks only whether `completed/08` is nonempty. It does not validate the fingerprint against current code and selections.

**Impact:** an optional module can proceed after required behavior or choices change, while the required dashboard would identify Phase 8 as stale. This is a readiness inconsistency, not a tamper-resistant security boundary; the user owns these state files.

**Remediation:** introduce one shared prerequisite check for current recorded completion, then separate that from live health and manual attestations. Reuse it in dispatchers and direct runners. Test fixtures should create legitimate fixture fingerprints through a controlled helper.

**Acceptance:** pending, malformed and stale markers block apply consistently; current completion allows it. Status and apply explain the same reason. Current fingerprints must still not imply perpetual live health.

### F11 — Software presence is not sufficient evidence of authenticity or approval

**Location:** [application detection](../../src/core/application-ownership.sh), lines 184–246; [installer](../../install-day-one-mac), lines 88–106; [architecture trust statement](../../docs/explanation/ARCHITECTURE-AND-STATE.md).

Application detection checks path/bundle metadata, or executable presence for CLIs. Bundle IDs are not publisher signatures. The public installer correctly labels checksum verification as integrity-only; build attestation is optional. There is no organization-defined publisher, version or approved-source policy.

**Impact:** all catalogue results need a narrower interpretation: “payload present” is not “trusted, supported, licensed and policy-approved.” Default installation relies on the download source for both archive and checksum. These are acknowledged trust boundaries, not demonstrated supply-chain compromise.

**Remediation:** represent presence, owner, observed version, architecture, signing/notarization evidence and policy approval separately. Managed deployments should consume verified immutable artifacts through an approved distribution path. Preserve a practical new-Mac bootstrap: requiring `gh` before the runtime cannot be the only enterprise trust option. Use verified MDM packages or an independently approved bootstrap path where appropriate.

**Acceptance:** mismatched publisher/architecture/version produces review without deleting the app. Publisher evidence is tied to the observed file. Missing provenance cannot be called verified publisher identity.

### F12 — “Reproducible” currently means reconstructable choices, not identical versions

**Location:** [toolchains](../../src/setup/phases/06-toolchains.sh), `fnm install --lts --use` and `uv python install`; [Phase 8 Brewfile handling](../../src/setup/phases/08-verification.sh); [database images](../../src/modules/configure-databases.sh), lines 315–339; [project guide](../../docs/explanation/PROJECT-GUIDE.md), development-stack section.

Runtime, Python and container selections resolve moving versions. The Brewfile captures installed package intent but does not alone freeze all package bytes. Project lockfiles are encouraged, but there is no machine-level snapshot tying observed versions to the selected policy and installer commit.

**Impact:** two machines using the same repository revision on different dates can receive different interpreters, packages and images. Exact cross-device equivalence cannot be inferred from matching phase markers. Conversely, freezing everything indefinitely would create patch risk.

**Remediation:** define two supported modes: rolling personal setup and a versioned managed baseline. Record runtime release/commit, macOS build, catalogue revision, actual package/interpreter versions, container digests, selected ownership and approved deviations. Pin project runtimes and package managers at project level; provide controlled baseline refresh and patch deadlines at machine level.

**Acceptance:** compare two fresh setups against the same policy and report all differences explicitly. A baseline refresh is reviewable and does not silently invalidate recovery assumptions.

### F13 — Corporate network integration has no acceptance contract

**Location:** [foundation](../../src/setup/phases/02-foundation.sh), [hosting checks](../../src/core/hosting-auth.sh), [first-boot guide](../../docs/setup/assisted/01-first-boot-and-decisions.md).

Downloads and provider tests are present, but there is no coordinated acceptance for enterprise Wi-Fi/802.1X, VPN, split DNS, proxy/PAC, managed CA trust, client-certificate expiry or management connectivity. This audit's separate skill-search certificate error is an environment observation, not proof that Day One Mac's downloads fail.

**Impact:** a machine can pass local readiness while package acquisition, private registries or managed services fail on a corporate network. Failure rate and support cost were not measured.

**Remediation:** add opt-in, bounded diagnostics against policy-approved endpoints and record DNS, connection and TLS stages separately. Inventory ownership of VPN/proxy/certificate configuration without collecting secrets. Provide recovery guidance through IT; never recommend disabling TLS validation or bypassing required VPN/security controls.

**Acceptance:** verify home network, corporate network and VPN-on/off cases with the appropriate allowlist, certificates and identity. MDM reachability must follow current [Apple network guidance](https://support.apple.com/guide/deployment/configure-your-network-for-device-management-dep2bcde692e/web), not a frozen unofficial port list.

### F14 — Backup and migration need application-level recovery evidence

**Location:** [Stage 0 restore confirmation](../../src/preflight/prepare-existing-mac.sh), lines 1067–1092; [restore staging](../../src/core/restore-staging.cjs); [migration guide](../../docs/how-to/modules/advanced/20-restore-and-migrate.md); [native acceptance](../acceptance/ACCEPTANCE.md).

The automatic Stage 0 read-back copies the snapshot README, then correctly asks the user to restore a representative file. Module 20 verifies selected regular-file bytes but intentionally excludes hidden data, credentials, metadata and live application/database import. Its eight native checks passed. Neither result establishes end-to-end recovery of a user's workload.

**Impact:** byte-correct staging can coexist with missing ACLs/xattrs, lost executable bits, absent application state or an unusable database export. Scope is data-dependent; total migration completeness and recovery duration are unknown.

**Remediation:** classify data and assign a recovery method: repositories/worktrees and unpushed work, documents, metadata-sensitive files, database logical exports, application exports and separately managed credentials. Define backup schedule, encryption/key custody, retention and recovery objectives. Preserve the narrow staging contract; add separate runbooks rather than silently widening it.

**Acceptance:** restore representative samples from each selected class to a disposable destination, open them in the owning application, validate database records, and verify critical metadata. Record actual RPO/RTO and exceptions before destructive preparation. Never substitute the README probe for the human/data restore check.

### F15 — Peripheral compatibility is outside current acceptance

**Location:** [required phase catalogue](../../src/core/required-phase-catalog.sh), [macOS preferences guide](../../docs/setup/assisted/MACOS-SETTINGS.md), [new-device blueprint](../../docs/reference/NEW-DEVICE-SETUP-BLUEPRINT.md).

There is no device-specific acceptance matrix for displays/docks, USB/Thunderbolt, audio/camera, printers, security keys, accessibility devices and external backup hardware. User-preference configuration is not peripheral compatibility testing.

**Impact:** every applicable physical peripheral remains unverified, especially across OS upgrades, sleep/wake and docking. No malfunction was observed because no hardware test was performed.

**Remediation:** add a role-specific checklist with hardware model, connection, firmware/driver version, OS support, owner and result. Prefer supported native interfaces and approved signed drivers. Preserve accessory-approval prompts; Apple documents them for applicable Apple-silicon laptops in [accessory access guidance](https://support.apple.com/en-gb/102282).

**Acceptance:** test reconnect, sleep/wake, display resolution/scaling, audio routes, camera consent, printing, hardware authentication and backup-drive unlock/read-back on the actual pilot hardware. Unsupported accessories produce documented exceptions.

### F16 — Supported OS/configuration claims exceed recorded integration evidence

**Location:** [CI](../../.github/workflows/validate.yml), `macos-26`; [platform gate](../../src/core/platform.sh); [compatibility statement](../../docs/explanation/PROJECT-GUIDE.md); [release acceptance](../acceptance/ACCEPTANCE.md).

CI uses one OS label. The platform gate checks Darwin/arm64 but no supported OS range. Documentation includes macOS 27 support; this audit exercised macOS 26.7.1 only. Native Module 20 does not substitute for a full fresh-user run.

**Impact:** there are 96 nominal track × stack × authentication × preset combinations before ownership/shell choices and invalid-combination constraints. A single default fixture cannot prove their integration. Unsupported older macOS versions are not rejected early by the common gate.

**Remediation:** publish minimum/tested/current OS support, align that with dependencies, and add a constraint-aware test matrix. Use pairwise coverage plus all security-critical combinations. Test macOS 26 and 27 where those are the supported targets, system Bash 3.2, paths with spaces/Unicode, managed standard users and clean login/restart behavior. Apple's [OS 27 compatibility guidance](https://support.apple.com/en-us/127455) and [Homebrew's current requirements](https://docs.brew.sh/Installation) should be checked during each baseline refresh.

**Acceptance:** every supported OS has a retained fresh-user run; invalid choices fail before mutation; releases retain machine/configuration evidence tied to the candidate. Label untested combinations honestly.

### F17 — Documentation duplicates choices and still contradicts executable behavior

**Location:** [project guide](../../docs/explanation/PROJECT-GUIDE.md), lines 134–144, 350 and 512–515; [Phase 1 guide](../../docs/setup/assisted/01-first-boot-and-decisions.md), Step 1.7; [historical documentation audit](DOCUMENTATION-AUDIT.md); compare [Start Here](../../docs/START-HERE.md), preset selection, and [Phase 7](../../src/setup/phases/07-editor.sh), core handling.

The project guide's hosting table omits Track 4. It marks VS Code Phase 7 for everyone and says Raycast/Warp remain in the base, although core skips them. Phase 1 similarly says VS Code remains required. The earlier documentation audit describes itself as current-state evidence but uses a September scope/count and older behavior.

**Impact:** readers choosing the minimal route can reasonably conclude that declined applications are mandatory. At least three independent claims conflict with the executable contract; the historical audit can be mistaken for evidence for today's revision.

**Remediation:** derive selection/capability tables from one registry and test them. Apply Diátaxis deliberately: one beginner tutorial per route, focused how-to/recovery pages, generated command/selection reference, and architecture explanation. Keep historical audits immutable but label their exact commit and scope; link a clearly identified latest assessment. Explain artifact-ready, manually verified and live-health states consistently.

**Acceptance:** core and recommended routes, all four tracks, authentication options and ownership modes agree across wizard, reference and guide. Every claim of completion states its evidence and remaining manual work. The documentation browser continues to export all user-facing guides from the allowlist.

### F18 — Performance and usability improvements need measured budgets

**Location:** [database configuration](../../src/modules/configure-databases.sh), container creation; [shell setup](../../src/setup/phases/05-dotfiles.sh); [restore implementation](../../src/core/restore-staging.cjs); [documentation reader CSS](../../src/docs/docs-browser.css) and [terminal UI](../../src/core/terminal-ui.sh).

There are no declared budgets for setup time, shell startup, background memory/CPU, application launch or large restores. The plan measurement was fast, but cannot justify broader optimization claims. Databases restart automatically and have no individual resource caps. Restore deliberately hashes data repeatedly for safety, which can dominate slow external-drive workloads.

**Impact:** possible memory contention, slower login or long transfer time remains unquantified. A 2.2 MiB offline reader is not by itself a performance defect. The reader has useful accessibility infrastructure, but live keyboard, VoiceOver, zoom and narrow-screen behavior were not tested. The CSS currently declares a light color scheme only.

**Remediation:** measure before optimizing. Collect clean login-shell p50/p95, baseline idle resources, application first/second launch, required-setup active versus waiting time, and representative backup/restore throughput. Set policy budgets and compare before/after on the same hardware. Offer deliberate database startup/resource choices. Investigate hashing cost without removing integrity checks. Test terminal and reader accessibility; add theme adaptation only where users need it.

**Acceptance:** publish repeatable measurements with hardware, OS, dataset and sample count. No accepted change weakens checksums or platform security for speed. Record keyboard/VoiceOver/zoom results separately from automated markup tests. For the reader, use the Impeccable adapt/harden/clarify checks as appropriate, followed by a bounded polish pass; no live WCAG compliance score is claimed here.

### Security and compliance interpretation

No named organizational standard was provided. Therefore this report does **not** assert CIS, NIST, ISO 27001, SOC 2 or regulatory compliance/noncompliance. The missing controls are assessed against the requested managed-workstation capability and practical security risks.

Choose and approve a baseline with the organization's security owner. The [NIST macOS Security Compliance Project](https://pages.nist.gov/macos_security/) supplies OS-specific security guidance and baseline tooling; its [baseline model](https://pages.nist.gov/macos_security/baselines/what-are-baselines/) is an appropriate reference for mapping requirements and exceptions. Do not import an entire benchmark blindly or treat a local PASS as independent compliance certification.

Zero-trust acceptance should include device posture, identity, authorized service access, least privilege and approved exceptions. Loopback binding, an administrator account, an installed agent or a historical phase marker alone does not establish those properties.

## Implementation Plan

### Staffing, assumptions and timeline

Plan for **6–8 calendar weeks**, approximately **35–55 engineering person-days**, with one experienced maintainer and a second engineer/QA contributor at roughly half-time. Allocate a Mac/MDM administrator and security owner for **6–10 person-days** across policy definition, enrollment testing and sign-off. These are planning estimates, not delivery commitments; baseline selection and access to test devices are prerequisites.

Technical resources:

- Disposable Apple-silicon test users/devices or suitable VMs, with real hardware for startup, FileVault and peripheral acceptance.
- At least one personal and one organization-enrolled pilot Mac; supported OS versions represented.
- MDM test group/tenant access, test identity-provider accounts, approved elevation and recovery escrow visibility.
- Corporate/home/VPN network test paths; managed certificates and a private registry/provider test repository.
- Encrypted external APFS test storage plus synthetic document, repository, database and metadata fixtures.
- Existing CI tooling, a test release channel, retained private evidence and access to repository protection settings.

Do not implement every enhancement as a single change. Each phase below should produce independently reviewable commits/PRs and preserve the existing public command contract where possible.

### Phase 0 — Establish the decision and evidence contract

**Timing:** days 1–2. **Owners:** maintainer, Mac administrator, security owner. **Effort:** 1–2 engineering days plus policy review.

1. Agree personal and managed support boundaries, supported OS versions and the organizational baseline.
2. Create a control/ownership matrix and define PASS, FAIL, UNKNOWN, MANUAL and approved-exception semantics.
3. Record this audit's revision and evidence; turn F01–F18 into issues with owners and acceptance criteria.
4. Mark managed readiness and untested capabilities as pending in user-facing guidance.
5. Reserve pilot devices and test accounts; define data-handling rules for private evidence.

**Exit:** scope and ownership approved; no invented compliance standard; reproducible issue list and test inputs exist.

### Phase 1 — Repair misleading gates and sensitive reporting

**Timing:** week 1 into week 2. **Owners:** maintainer with reviewer. **Effort:** approximately 7–10 engineering days. **Findings:** F01–F04, F08–F10; contain F07 by refusing unverified endpoints.

1. Fix argument forwarding in the validator and add a failing-sentinel regression.
2. Add shared credential-free remote formatting and synthetic redaction tests before changing reports.
3. Replace cached-remote recovery inference with exact live-ref verification and bounded failure handling.
4. Replace editor string checks with JSONC-aware checks and a clearly limited effective-settings claim.
5. Make advanced audit use shared selections and propagate probe failures as unknown/fail.
6. Consolidate current prerequisite validation across optional dispatch and direct runners.
7. Bind release publication to validation of the actual candidate SHA, including manual dispatch.
8. Run relevant fixtures, full validation/lint and packaged acceptance; retain results for the changed candidate.

**Exit:** all reproduced false passes are covered by failing-before/passing-after tests. A stale or unvalidated release cannot publish. No synthetic credential appears in reports. Core selections produce consistent results.

**Main risks:** false rejection of legitimate URLs/settings, changed CLI exit behavior, publication disruption. **Mitigation:** compatibility fixtures, clear error messages, a non-public test release and staged rollout.

### Phase 2 — Add managed onboarding and security acceptance

**Timing:** weeks 2–4. **Owners:** maintainer and Mac/MDM administrator; security review. **Effort:** approximately 10–15 engineering days. **Findings:** F05–F06, managed parts of F11 and F13.

1. Add deployment-mode/schema migration with a conservative default for existing state.
2. Implement read-only management detection and explicit ownership of policy-controlled settings.
3. Define standard-user/elevation paths and guide the approved account/SSO process through its owning system.
4. Add security-control probes and manual evidence requirements, especially FileVault recovery and update compliance.
5. Integrate managed software publisher/version approval without taking ownership from MDM.
6. Add network and certificate diagnostics that explain the failing stage without bypasses or secrets.
7. Pilot with one managed standard user and one personal user; test interrupted setup, deferred enrollment and expired/missing evidence.

**Exit:** the project can tell an operator which required authority/control is missing and cannot call that Mac organizationally ready. Personal setup remains usable without MDM.

**Main risks:** enrollment/token lockout, MDM/local-setting conflict, overbroad permissions. **Mitigation:** no automatic account/token repair, non-production MDM scope, policy-owner precedence, tested break-glass recovery and explicit manual handoff.

### Phase 3 — Harden software, containers and recovery

**Timing:** weeks 4–5. **Owners:** maintainer, QA contributor and data/application owners. **Effort:** approximately 9–13 engineering days. **Findings:** F07, F11–F14.

1. Pin Docker endpoint identity and add adoption/ownership checks before creating resources.
2. Add reviewed database credentials, image digests, resource budgets and spec/drift verification.
3. Record machine baseline versions and permitted drift; distinguish rolling personal setup from approved managed snapshots.
4. Define trusted installer/bootstrap distribution and provenance evidence for managed deployments.
5. Create application-level recovery fixtures and runbooks; add database import verification and metadata-sensitive cases.
6. Rehearse offline, disconnected, insufficient-space and changed-source/destination conditions in disposable environments.
7. Measure backup/restore duration and agree workload-specific recovery objectives.

**Exit:** remote daemon drift and accidental volume adoption are blocked; two baseline installs have explainable differences; selected data classes have demonstrated recovery procedures.

**Main risks:** existing database data becomes inaccessible after credential/image changes, rigid version policy delays patches, backup scope accidentally expands. **Mitigation:** explicit migration/adoption procedures, preserved old volumes, patch windows, no automatic data conversion and checksummed test restores.

### Phase 4 — Prove integrated behavior and simplify the experience

**Timing:** weeks 6–8, with documentation/test preparation earlier. **Owners:** QA contributor, maintainer and onboarding owner. **Effort:** approximately 8–12 engineering days. **Findings:** F15–F18 and final verification of all earlier findings.

1. Add supported OS/configuration coverage using pairwise selection tests and explicit security-critical cases.
2. Execute full fresh-user Phases 1–8 on personal and managed pilots; record every manual gate and restart result.
3. Complete the peripheral matrix on real hardware and capture compatibility exceptions.
4. Reconcile the decision tables, check them against the shared selection registry, and restructure duplicated explanations by document purpose.
5. Run keyboard, plain-terminal, narrow-screen, zoom and VoiceOver onboarding checks.
6. Establish shell/application/setup/restore performance baselines and measure any optimizations against them.
7. Build one final candidate, run complete acceptance, verify exact-commit provenance and review release notes.
8. Expand a small pilot group only after no unresolved P1 remains; retain a rollback and support plan.

**Exit:** signed-off acceptance evidence for each supported deployment type, current documentation and a release candidate whose source, artifacts and checks agree.

**Main risks:** combinatorial test growth, undocumented manual steps, hardware-specific failures. **Mitigation:** constraint-aware matrix, recorded pilot transcripts, explicit unsupported combinations and hardware ownership.

### Final acceptance matrix

| Area | Required proof | Blocking condition |
|---|---|---|
| Release | Candidate SHA, required checks, tested archive hash and matching provenance | Different/unvalidated SHA, failed required check, missing required provenance |
| Selection consistency | Same decisions respected by setup, status, optional apply and audit | Declined tool required, stale prerequisite accepted, contradictory readiness |
| Accounts/MDM | Deployment mode, account role, enrollment and policy-owner confirmation | Unmanaged corporate device, inappropriate privilege, unknown required account state |
| Security | All applicable controls pass or have approved exceptions; recovery custody confirmed | Required failed/unknown control, unverified recovery path |
| Software | Approved owner/source/publisher/version plus actual first-launch and update behavior | Conflicting ownership, untrusted publisher, unsupported version or failed launch |
| Git/identity | Actual provider access, correct author/signing behavior, live remote recovery commit | Cached-only recovery assurance, wrong identity, missing remote branch |
| Network | Required services work under approved corporate/home/VPN conditions | Required DNS/TLS/certificate/MDM/private-registry failure |
| Containers | Verified local endpoint, exact spec, owned/adopted data, healthy services | Remote/ambiguous endpoint, unreviewed data adoption, unsafe binding or health failure |
| Recovery | Selected data classes restored and opened/imported; metadata and RPO/RTO checked | Unrestorable class, incomplete scope, failed decrypt/unlock or unacceptable recovery time |
| Hardware | Approved peripheral matrix including reconnect and sleep/wake | Required device fails or demands an unapproved security reduction |
| UX/performance | Fresh-user completion, restart persistence, accessibility results and repeatable measurements | User cannot complete required flow; unacceptable measured regression |
| Documentation | Versioned route/selection reference and evidence for the tested revision | Claims contradict commands or imply unperformed verification |

### Maintenance after implementation

At each release, retain the exact candidate evidence and repeat affected behavioral tests. Rehearse supported OS/MDM combinations on OS changes, and application recovery on relevant format/version changes. Assign owners and review dates to baseline controls, vendor references, secrets/report retention and peripheral exceptions.

Use the existing NIST/Apple/vendor sources as maintained references, with organization-approved interpretation. Do not turn this audit's date, file counts, test environment or proposed budgets into permanent product guarantees.

### Work completed by this audit

The deliverable is this report, prioritized findings, implementation plan and local validation evidence. No production setup, security setting, account, credential, app installation, repository implementation or release workflow was changed. Test fixtures used disposable locations. The APFS test image was detached; its evidence was retained. Remediation remains planned work.
