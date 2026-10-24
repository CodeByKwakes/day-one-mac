# Prepare macOS

Establish the operating-system and account baseline before developer tooling.
This is a manual task. Read the [shared prerequisites](../../shared/prerequisites.md)
and retain recovery information outside this Mac.

## 1. Finish account setup

Complete macOS Setup Assistant using the permanent daily account. On a managed
Mac, follow IT enrollment and account policy.

Expected result: the intended account can sign in, and the device owner has
confirmed the approved elevation method.

## 2. Review software updates

Open **System Settings > General > Software Update** and install the updates
approved for this device. Restart if requested.

Expected result: the installed OS meets the supported range and applicable
organisation deadline. Do not bypass a managed deferral.

## 3. Check native execution

Run `uname -m` in Terminal.

Expected result: `arm64`. If it reports `x86_64`, inspect the terminal's Rosetta
setting and the hardware before proceeding.

## 4. Enable and verify FileVault

Open **System Settings > Privacy & Security > FileVault**. If it is off, follow
the approved encryption and recovery process. Store or escrow recovery material
as required; its only copy must not be on the encrypted disk.

Expected result: `fdesetup status` reports FileVault is on. A recovery-key label
alone does not prove recovery; complete the agreed recovery check.

## 5. Check operating-system protection

Run `spctl --status`.

Expected result: assessments are enabled. Complete the remaining firewall,
System Integrity Protection (SIP), update and recovery checks in
[shared verification](../../shared/verification.md). Ask IT about a managed
mismatch instead of disabling controls.

## Optional preferences

On a personal Mac, change only preferences you need:

| Preference | Location | Verify |
|---|---|---|
| Finder extensions/path/status | Finder Settings and View menu | A test file shows the expected extension and location |
| Dock behaviour | System Settings > Desktop & Dock | Open and switch between two applications |
| Keyboard and shortcuts | System Settings > Keyboard | Check shortcuts in the intended application |
| Trackpad gestures | System Settings > Trackpad | Try the selected gesture |
| Screenshot destination | Screenshot app, Options | Capture a harmless test and confirm its location |
| Battery behaviour | System Settings > Battery | Review the setting appropriate to your power source |

Managed preferences remain with IT. Optional preferences can be skipped without
blocking the development foundation. Record the original value before a change
so it can be restored through the same UI.

## Verify and continue

Record the OS build from `sw_vers`, protection results and recovery evidence in
private notes. Continue to [Apple tools and Homebrew](homebrew.md).

## Troubleshooting

| Symptom | Action |
|---|---|
| A setting is unavailable or managed | Ask the policy owner; do not remove management profiles |
| Encryption is still in progress | Keep power connected and recheck before claiming completion |
| Recovery evidence is missing | Establish the approved recovery method before developer setup |

## Review application permissions

1. Open **System Settings → Privacy & Security**. Expected: the application-permission categories are visible.
2. Inspect **Accessibility**, **Full Disk Access**, **Files and Folders**, **Screen & System Audio Recording**, **Automation** and **Developer Tools**, one category at a time. Expected: you can identify the application and feature behind each approval; names vary slightly by macOS release.
3. Disable a stale approval only after confirming that the application or feature no longer needs it. Expected: unrelated application approvals remain unchanged.
4. Exercise a selected application's feature and grant only the permission it requests for that feature. Expected: the feature works with the narrowest available permission. Terminal, Warp, VS Code, AI clients and Docker do not all need Full Disk Access by default.
5. Run `fdesetup status`. Expected: FileVault remains on, or the managed-device policy and recovery owner explain its current state.

Record the reviewed permissions privately. If a needed feature stops working, re-enable only its identified permission through System Settings. Never copy macOS privacy databases between machines.

## Review login items and background services

1. Open **System Settings → General → Login Items & Extensions**. Expected: login and background entries are listed.
2. Check each entry against the applications you use daily. Expected: each enabled entry has a known owner and purpose, such as the password manager's agent or a container engine used every day.
3. Disable an optional entry you no longer need at sign-in. Expected: the application remains installed and can still be opened manually. Preserve employer-managed services.
4. Sign out and back in at a convenient time, then open one selected workflow. Expected: required agents work and optional utilities do not start unnecessarily.

Prefer each application's own login setting when it provides one. Re-enable that same setting to undo the change; disable background startup before uninstalling an application.

## Choose browsers and menu-bar tools by role

| Role | Decision and expected result |
|---|---|
| Personal default | Choose one browser and check its active account before enabling sync |
| Work-managed browsing | Use the employer-required browser/profile; managed policy remains with IT |
| Compatibility testing | Choose one additional rendering engine when a project needs it |
| Automated browser tests | Let the project tooling own its browser binaries and versions |
| Menu-bar management | Choose at most one utility for the same hiding/organisation workflow |

Configure a small set of [Raycast actions](apps/raycast.md) manually before exporting settings. Keep Spotlight indexing enabled in either launcher mode. Review browser extensions and password-manager account pairing before importing an old profile. Store app exports in encrypted backup; record permission and login-item decisions in a private checklist.
