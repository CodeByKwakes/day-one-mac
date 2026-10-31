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
