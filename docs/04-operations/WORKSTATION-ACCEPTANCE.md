[← Workstation readiness](../20-reference/WORKSTATION-READINESS.md) · [Recovery and migration](../03-advanced/20-restore-and-migrate.md)

# Workstation pilot acceptance and recovery

Use this checklist on each supported deployment type before broad rollout.
Keep test records private, identify the tested runtime/policy and assign an
owner to every exception. A successful automated package test is not a fresh
user, MDM, hardware or application recovery test.

## Support and test matrix

| Scope | Current contract | Required release evidence |
|---|---|---|
| Hardware/process | Apple silicon, native arm64, system Bash 3.2 | Native and Rosetta-rejection tests |
| Dependency range | macOS 15–27; policy may narrow this | Do not confuse accepted range with completed pilot coverage |
| CI | macOS 15 and 26 jobs | Both jobs successful for the release candidate's changes |
| macOS 27 | Fresh-user/managed pilot required | Retained device run before organization rollout; CI preview labels are not assumed |
| Base selections | 4 tracks × 3 stacks × 4 authentication modes × 2 presets | 96 read-only plan cases plus focused behavioral tests |
| Ownership/accounts | Personal; managed standard user with approved elevation | Actual enrollment, token, policy and recovery evidence |
| Access/experience | Terminal keyboard/plain modes and reader keyboard/VoiceOver/zoom | Real interaction results; markup tests alone are insufficient |

The 14 October 2026 audit's native APFS evidence was on macOS 26.7.1. This does
not certify full onboarding on every supported OS. Runtime compatibility and
CI results must be refreshed when Apple, Homebrew or application requirements
change. GitHub's [runner reference](https://docs.github.com/en/actions/reference/runners/github-hosted-runners)
is the source for available runner labels.

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
   record (script-assisted route) or the manual acceptance record.
8. Re-run final verification. Expand the pilot only after required failures and
   unknowns are resolved or the policy owner approves explicit exceptions.

## Recovery by data class

Module 20 stages selected regular-file bytes and detects collisions/drift. It
intentionally does not restore hidden credentials, metadata, live application
state or whole databases. Preserve that boundary and use separate restore
methods for each selected class.

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

The script-assisted route can record shell measurements explicitly:

```bash
day-one-mac readiness --benchmark-shell "$HOME/Downloads/shell-timings.json" --shell /bin/zsh
```

This deliberately executes the selected shell's startup files twenty times;
it is not a read-only configuration inspection. Each launch has a five-second
limit. Use `/opt/homebrew/bin/zsh` only when it is the selected approved shell.
The command never runs automatically during onboarding. Do not interpret a
fast plan command or small HTML file as evidence about application performance.

Test keyboard-only navigation, visible focus, plain/ASCII terminal output,
VoiceOver announcements, 200% zoom and narrow reader layouts. Confirm that an
interruption explains completed work and the exact next action. Record task
completion and observed friction; do not infer WCAG compliance from source review.
