# Accept a documentation and skill snapshot

Use this checklist for current manual guides, portable skills, native plugins
and the static reader. Record the candidate source identity and observed results
privately. A working-tree check does not establish public availability or device
acceptance. Historical runtime rehearsals remain in `ACCEPTANCE.md`.

## Verify local artifacts

1. Run `pnpm run validate:complete` from the candidate source.
2. Run the pinned Skills CLI acceptance in CONTRIBUTING.md.
3. Supply the approved native client executables to the optional plugin tests.
4. Run `pnpm run docs:check-links` with approved network access. Resolve broken
   destinations and manually inspect access-limited responses.
5. Build the website/offline ZIP and native plugin handoff outside the checkout.
   Extract both; verify revision/checksum and the intended contents.
6. Open the reader in a browser. Test direct links, body search, copying a command,
   keyboard navigation, narrow layout, 200% zoom and print. Record VoiceOver
   results separately from the automated DOM fixture.

Expected: the candidate passes local checks with retained logs. Do not mark
client invocation, macOS provisioning or accessibility acceptance from fixtures.

## Verify the published source after approved publication

Publication is a separate action. Once the selected revision is public, use
disposable installation workspaces and the exact published source:

| Surface | Evidence to record | Required comparison |
|---|---|---|
| GitHub skills | Revision, CLI version, listed/installed package names and workflow files | Match the candidate catalogue and the requested capabilities |
| Handbook | Deployed `snapshot.json` revision and content fingerprint | Match the approved revision and downloaded offline snapshot |
| Native plugin | Archive digest, artifact version, client version and installation scope | Match the reviewed handoff, installed version and loaded skill |
| Manual source archive | Reviewed revision and extracted public files | The manual journey and referenced assets work without contributor dependencies |

Listing only `day-one-mac` is insufficient when the release adds bundled
workflows. Read the installed workflow files and perform a harmless invocation
in each selected client. Never publish a newer local guide as proof that the
default GitHub branch already contains it.

## Complete clean-device pilots

Use disposable Apple-silicon accounts/devices with recovery prepared. Run both
manual and AI-assisted journeys against the minimum supported macOS version and
the current approved version. Record the exact OS build and selected software.

- Begin with no usable Git, Node, Homebrew or editor configuration. Confirm each
  prerequisite is installed before the first command that needs it.
- Include core Apple Zsh/user-owned settings, Python-only, and Node selections.
  Optional aliases, Homebrew Zsh and productivity applications may remain absent.
- Complete a real project check, restart/new-session check and independent sample
  restore using the [private acceptance record](../../docs/shared/private-evidence.md#copy-a-setup-acceptance-record).
- For managed-device claims, use the approved standard-account/elevation process
  and test the organisation's network, policy and recovery controls.
- Have a first-time user follow the guide without coaching. Record every stopped
  step. Have an experienced user locate advanced configuration and recovery.
- Test selected optional capabilities through their owning guides; leave unrelated
  hardware, provider and account workflows explicitly untested.

Sign off only the tested route/capabilities, with reviewer, date, evidence expiry
and unresolved items. Use the [client acceptance matrix](../../docs/shared/reference/client-acceptance.md)
for existing scope boundaries. Unknown required checks prevent a readiness claim.

### Use a fresh macOS VM for software acceptance

A newly installed macOS guest on an Apple-silicon host can exercise the clean
software-installation journey. Record the environment as **clean VM**, with
host/guest OS builds, virtualization app/version and any guest tools. Keep
physical-device, managed-device and first-time-human acceptance separate.

1. Confirm the host's owner permits the virtualization app, local guests and
   selected network access. Use that app's approved installation/update owner.
2. Create a new native macOS guest from an Apple restore image compatible with
   the host. Record the selected stable release; do not assume the latest image
   matches the host or covers the minimum supported macOS version.
3. Have the user complete licence acceptance and guest account creation. Start
   without migration, restored developer configuration or copied account tokens.
4. Before developer installations, record `sw_vers`, `uname -m`,
   `xcode-select -p` and availability of the selected tools. A stock Apple Git
   stub does not establish usable Git or installed Command Line Tools.
5. Shut down the guest and preserve a full baseline copy including its virtual
   disk. Use separate full copies for the manual and AI-assisted journeys.
   Do not assume a configuration-only copy or suspended state is a clean baseline.
6. Transfer only the reviewed candidate's guides and skill package. Record its
   content fingerprint, including uncommitted changes when applicable. Keep
   host home folders, account credentials and developer caches outside the guest.
7. Run the applicable checks below inside each guest. Record interventions and
   failures, restart the guest, test a real project and restore a sample. Repeat
   on the minimum supported OS only when that image is available and compatible.

For UTM, the [macOS guest guide](https://docs.getutm.app/guest-support/macos/)
describes Apple restore images and the [actions guide](https://docs.getutm.app/basics/actions/)
distinguishes full copies from configuration-only copies. Follow the installed
version's controls; record the app version with each pilot.

| Acceptance area | Evidence a VM run can establish | Remaining boundary |
|---|---|---|
| Missing prerequisites, shell and language setup | Observed installation order and fresh-session/project checks | Only the tested guest OS and selections |
| Skill installation and recovery | Actual copy/install, discovery, scoped update and restore results | A fixture or file check alone does not prove client discovery |
| Provider and account workflows | Actual approved sign-in and harmless request in the guest | No pass without a live response |
| Novice usability | A first-time person follows the guest journey without coaching | Agent execution does not establish this |
| Physical displays, device encryption/recovery and company controls | No physical-device acceptance from the software pilot | Test on the relevant hardware and managed environment |
| Container engines | Only observed success in a supported nested-virtualization configuration | Check host, guest and engine support separately |

If a required device control cannot be exercised, mark it **untested**. A
continued software-only experiment does not sign off the complete workstation.
Keep the untouched baseline and recovery copies; never erase or format disks.

### Run the first spare-Mac pilot

Use the spare Apple-silicon Mac only after its owner approves the test scope and
recovery plan. Do not erase or format it for this procedure. A new account can
isolate user settings, but it does not remove system-wide developer tools. If
Git, Homebrew or other prerequisites are already usable, record that limitation;
the run cannot prove those fresh-install steps.

1. Copy the [private acceptance record](../../docs/shared/private-evidence.md#copy-a-setup-acceptance-record)
   outside the checkout. Record `sw_vers`, `uname -m`, the selected source revision,
   device ownership and the [supported macOS floor](../../docs/shared/prerequisites.md).
2. Inventory existing prerequisites without installing anything. Record which
   fresh-install preconditions are met and which remain untested.
3. Have a first-time user follow [Start here](../../docs/START-HERE.md) and the
   [manual base sequence](../../docs/setup/manual/README.md#follow-the-base-setup).
   Record every unclear or blocked step before offering help. Start with Apple
   Zsh and one project language; optional productivity apps may remain absent.
4. Verify the selected real project, open a new terminal, restart as approved,
   and restore an independent sample from the chosen backup owner. Preserve
   errors and recovery references privately.
5. In a separate approved pilot, follow the [AI bootstrap](../../docs/setup/manual/ai/setup-assistant.md).
   Exercise manual skill copy before Node/Git are available, then verify skill
   discovery, a harmless provider response and the bounded tool-permission check.
6. Have an experienced user locate the selected capability's configuration,
   recovery and troubleshooting without coaching. Record navigation failures.
7. Repeat missing OS, language and managed-device combinations only in appropriate
   approved environments. An already configured Mac cannot fill a clean-device row.

Copy the matrix below into the private record. All rows begin **untested**;
replace a status only with observed evidence for that exact candidate.

| Check | Minimum supported macOS | Current approved macOS | Evidence required |
|---|---|---|---|
| Novice manual base, Apple Zsh, Python-only | Untested | Untested | Starting prerequisites, stopped steps, project/restart/restore results |
| Manual base with Node selected | Untested | Untested | Node owner, version, real project and fresh-shell result |
| AI bootstrap before Node/Git | Untested | Untested | Manual copy, client discovery, live response and bounded tools |
| Selected native plugin/client | Untested | Untested | Installed version, scope and live skill invocation |
| Advanced configuration and recovery discovery | Untested | Untested | Tasks, destinations found and unresolved confusion |
| Managed standard-account journey, if claimed | Untested | Untested | Approved elevation, network policy and recovery checks |

Store local validation logs separately from pilot evidence. A passing fixture
or native CLI artifact validator does not change any live row to **pass**.
