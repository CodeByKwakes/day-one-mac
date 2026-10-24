# Verify the selected workstation

Use one acceptance record for the selected route and policy. A phase marker,
package test or version command proves only its specific check. It does not
certify device health, account access, recovery or organisational compliance.

The [prerequisite matrix](prerequisites.md) owns the platform contract and the
difference between accepted OS versions and actual pilot evidence. Keep records
private and identify the tested device/account with non-secret references.

## Acceptance controls for both setup routes

Use this matrix before setup and again at final acceptance. The manual route
uses macOS/IT checks and a private operator-kept record; it does not require
Day One Mac commands. The assisted route uses the selected policy and current
device/account-bound evidence. Neither route replaces organization approval.

| Control | Personal Mac | Managed Mac | Acceptance evidence |
|---|---|---|---|
| Ownership and account | Personally administered account | Enrollment, daily standard account and approved elevation/recovery owner | IT verifies MDM, profiles, SSO and secure/bootstrap tokens where applicable |
| OS and updates | Supported OS with current applicable updates | Approved OS build and update deadline; do not bypass a deferral | Record OS build, policy revision and check date |
| FileVault and Gatekeeper | Both enabled | Both enabled, with recovery escrow verified by IT | Required in both routes; exceptions do not satisfy Day One Mac completion |
| Firewall and SIP | Enabled under the personal baseline | Organization-approved controls | Current observations; any supported exception needs an approval reference |
| Recovery | Separate recovery method and a successful recovery drill | Approved escrow, break-glass and workload recovery checks | Record outcome and custody references, never keys or credentials |
| Software and preferences | Selected software and reviewed personal preferences | Approved publishers/installers; IT owns managed preferences | Homebrew is provisioned by the approved administrator; local preference apply/restore is blocked |
| Organization acceptance | Add controls required for the workload | Startup, lock/sharing, endpoint agents, privacy, software/editor scopes, network, restoration, peripherals, performance and onboarding | Retained tests for every control in the approved policy; see [pilot acceptance](verification.md) |

Manual records identify the policy/baseline, device and account using private
non-secret references, reviewer, check time, expiry and evidence location. Use
the selected policy's evidence interval (personal default: seven days); renew
after expiry or relevant policy/device/account changes. Both routes keep user-approved notes; no manager evidence file is required. Never mark an untested control
as passed. An approved exception is distinct from an observed pass.

## Record results through the selected route

Manual users retain the check date, reviewer, expiry, result and evidence location
in private notes. Assisted users follow the
[policy and evidence reference](reference/workstation-readiness.md).
Both routes leave untested controls unknown; neither infers approval from a file's
existence. FileVault and Gatekeeper remain required completion controls.

## Personal and managed onboarding pilot

1. Select a disposable account/device, policy and approved OS build. Confirm
   independent recovery before reset; use Apple's supported UI and IT process.
2. Run the chosen route from its beginning. Record choices, active work time,
   download/wait time and every manual approval. Do not skip stopped gates.
3. Restart and open a clean terminal. Confirm shell, PATH, runtime versions,
   Git author/signing identity, provider access and actual remote backup commit.
4. Launch each selected application. Verify license/account access, approved
   publisher/version, update behavior and required privacy permissions.
5. For managed devices, verify enrollment, MDM profile ownership, standard-user
   behavior, approved elevation, SSO, token readiness and recovery escrow.
6. Test home, corporate and VPN paths against approved services. Record DNS,
   TLS, proxy, identity and certificate-renewal outcomes separately. Ask IT to
   resolve failures; do not bypass TLS/VPN/endpoint controls.
7. Complete the controls below, then enter current evidence in the readiness
   record (AI-assisted route) or the manual acceptance record.
8. Re-run final verification. Expand the pilot only after required failures and
   unknowns are resolved or the policy owner approves explicit exceptions.

## Recovery by data class

Use the owning manual recovery procedure for each selected data class. Do not
copy hidden credentials, live application state or whole database storage as
ordinary files. Rehearse recovery in a separate destination before relying on it.

| Data class | Recovery rehearsal | Record before destructive preparation |
|---|---|---|
| Repositories/worktrees | Recover unpushed commits and untracked work; verify branch/worktree identity and build a representative project | Source/destination revision and explicit exclusions |
| Documents | Restore samples from each important directory and open them in their owning apps | Checksums, readability and total scope |
| Metadata-sensitive files | Use a method preserving needed ACLs/xattrs/executable bits; verify them after restore | Required metadata and actual restored values |
| Databases | Create logical exports using the matching vendor tool; import into a disposable isolated instance and compare schema/record counts | Export compatibility, integrity and application query results |
| Application data | Use supported exports/backups; reopen in a clean application profile | Version compatibility, account requirements and missing data |
| Credentials/recovery | Use the approved password manager/MDM recovery process; test unlock/recovery without recording secret values | Custodian, recovery access and confirmation reference |

Specify backup frequency, encryption/key custody, retention and responsible
owner. Define RPO (maximum acceptable lost work) and RTO (maximum acceptable
recovery time) for the user's workload. Record actual last-successful backup,
restore duration and recovered-data age. A copied README or successful staging
hash is not a substitute for opening/importing restored data. Never erase the
source until the separately verified backup/recovery boundary is satisfied.

For existing Module 09 data, do not remove or relabel old volumes to satisfy the
new ownership gate. Back up using vendor tools, verify the export, and plan a
separate migration to reviewed resources. Preserve the previous daemon/context
and volumes until restoration has been demonstrated. Endpoint records and
image/spec records are evidence, not instructions to delete resources.

## Peripheral acceptance

Record only applicable equipment. Each row needs model, connection, firmware,
approved driver/version, OS, owner, result and test date. Use a documented
exception for equipment outside the role's scope.

| Equipment | Required checks |
|---|---|
| Dock/displays | Native resolution/scaling, all required ports, reconnect, sleep/wake and charging |
| Keyboard/pointing/accessibility | Layout, gestures, assistive-device compatibility and login-screen operation |
| Audio/camera | Input/output routing, call application, consent prompts and reconnect |
| Printers/scanners | Approved driver, test output, authentication and network reconnect |
| Security keys | Sign-in/signing and recovery path without exposing key material |
| Backup drive | Accessory approval, encrypted unlock, sustained transfer and representative restore |

Do not lower startup security or disable accessory approval to make a driver
work without a policy-owner decision. Apple describes [accessory approval](https://support.apple.com/en-gb/102282).

## Performance and usability measurements

Agree budgets before comparing changes. Initial pilot targets below are
**proposed review thresholds**, not measured product guarantees; owners may
replace them for the actual workload and hardware.

| Metric | Method | Initial review threshold |
|---|---|---|
| Login-shell startup | 20 launches on the same hardware/OS; report first, p50 and p95 | p95 above 1 second, or a repeatable increase over 20% |
| Idle overhead | Compare Activity Monitor after a five-minute settle, with the same apps/services | Investigate new sustained CPU use or memory pressure |
| Application launch | Five cold/warm observations for required apps | Compare with the pre-change pilot baseline; no universal time promise |
| Setup completion | Separate active work, downloads, OS updates and approvals | Investigate avoidable repeated questions or unexplained waits |
| Recovery throughput | Same encrypted drive, connection, file mix and byte count | Meet agreed RPO/RTO; investigate regression without removing integrity checks |

Measure shell startup only with explicit approval: launching a login shell
executes its startup files. Follow the [zsh guide](../setup/manual/shell/zsh.md)
and record the command, environment and observed timing. No benchmark runs
automatically during setup.

Test keyboard-only navigation, visible focus, plain/ASCII terminal output,
VoiceOver announcements, 200% zoom and narrow reader layouts. Confirm that an
interruption explains completed work and the exact next action. Record task
completion and observed friction; do not infer WCAG compliance from source review.
