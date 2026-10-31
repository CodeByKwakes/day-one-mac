# Pilot Atticus as an optional voice companion

Use Atticus for deliberate voice commands after the
[display and window workspace](workspaces.md) works. Keep Raycast responsible for
named layouts. Atticus is optional; it is not required to use Codex, Copilot,
Claude Code or any Day One Mac setup route.

## Decide whether it fits

Atticus is MIT-licensed, free software; its selected AI provider may require a
paid plan or metered service. The upstream README requires macOS 26 or newer and
lists Claude Code, Devin, Pi and an Anthropic-compatible route. It does not
establish a direct Codex or GitHub Copilot backend. Existing subscriptions to
those products alone do not establish that Atticus's provider is ready.
[Project and provider prerequisites](https://github.com/SaarthurR/atticus-mac).

Start with push-to-talk and one harmless window command. Leave wake-word,
Meeting Copilot, background agents and scheduled routines unused during the pilot.
Speech processing is local, but a selected AI backend can receive the prompt and
screen context. Do not treat local transcription as a guarantee that every
request stays on the Mac.

## Review the installation before building

The source review used version 1.5.4 at
[commit 780aa7724d2d0169041135d80d77e36fc7cfd9f9](https://github.com/SaarthurR/atticus-mac/tree/780aa7724d2d0169041135d80d77e36fc7cfd9f9).
This is a reproducible review baseline, not a claim that it is the newest or
safest release. Check current changes before selecting an update.

1. Check `sw_vers -productVersion`, `git --version`, `python3 --version` and
   `xcode-select -p`. Prepare missing build tools through their approved owners.

   Expected result: macOS 26+ and the upstream build prerequisites are available.
   Confirm your selected provider works independently before building the app.

2. Check that `~/.atticus`, `~/Applications/Atticus.app` and
   `~/Library/LaunchAgents/com.atticus.app.plist` are not existing installations.

   Expected result: either a new installation can proceed, or you stop and
   review the existing owner and private recovery copy. Do not overwrite a copy
   managed by somebody else.

3. For a new installation, fetch the source without executing its installer:

   ```bash
   git clone --no-checkout https://github.com/SaarthurR/atticus-mac.git "$HOME/.atticus"
   git -C "$HOME/.atticus" checkout --detach 780aa7724d2d0169041135d80d77e36fc7cfd9f9
   ```

   Expected result: the chosen source revision is available for inspection.
   These commands download code; they do not certify or launch the application.

4. Read `install.sh`, `build.sh` and the selected release's permission behavior.

   Expected result: you understand the build and startup changes before choosing
   to execute them. Do not substitute an unreviewed `curl | bash` installation.

The reviewed [build script](https://github.com/SaarthurR/atticus-mac/blob/780aa7724d2d0169041135d80d77e36fc7cfd9f9/build.sh)
creates `~/Applications/Atticus.app` and a login LaunchAgent. It can create/import
a local signing identity named **Atticus Local Signing**, with an ad-hoc fallback.
Building therefore has effects beyond compilation. Record these owned items
privately; preserve an existing signing identity rather than deleting it later.

## Build and limit the pilot

1. If the reviewed effects are acceptable, build the selected source:

   ```bash
   cd "$HOME/.atticus"
   bash build.sh
   ```

   Expected result: the app bundle builds, or a concrete dependency/signing error
   is reported. Live build and provider acceptance have not been tested by this
   repository's automated checks.

2. Open `~/Applications/Atticus.app` and select the intended AI backend in Settings.

   Expected result: provider status is usable without copying credentials into
   this repository, a saved layout or a shared skill.

3. Review app startup and updates. For a pinned pilot, turn automatic updates off
   under **About & Updates** and disable login startup if you want manual launches.

   Expected result: the app's lifecycle matches your choice. Update through the
   same source owner after reviewing changes and preserving private configuration.

4. Review **Account & Access**: decide whether to turn off **Count me as a user**;
   leave **Help improve Atticus** off unless its data sharing is wanted.

   Expected result: telemetry choices are explicit. Inspect the installed version
   if these labels change.

5. Grant only the permissions required by the selected feature. Window movement
   needs Accessibility; voice needs microphone/speech access. Screen context and
   calendar features have separate access implications.

   Expected result: a selected feature works without granting unrelated access.
   Declining a permission may make its feature unavailable.

6. Test push-to-talk with an unambiguous disposable window, for example:
   “Maximize Calculator on the laptop.” Check the resulting window yourself.

   Expected result: one intended window moves. Keep production database work,
   system setup, repository mutation and message sending outside this first test.

The default voice shortcut is Control+Option+Space. Review the fn dictation
binding against macOS's Globe action before enabling it. Keep Raycast's launcher
and the [documented shortcut owners](keyboard-shortcuts.md#workspace-and-voice-shortcuts).

## Understand the automation boundary

The reviewed [implementation](https://github.com/SaarthurR/atticus-mac/blob/780aa7724d2d0169041135d80d77e36fc7cfd9f9/atticus.py)
selects displays by built-in/external status or localized name; an unmatched
selection can fall back to the main screen. Identical monitor names and several
windows of one application need explicit testing. It is not an exact monitor-ID
restoration contract.

For Claude, the foreground path uses `bypassPermissions` with app-supplied tool
gates. Background behavior differs. Do not assume the normal interactive Claude
approval prompts or identical restrictions across all supported backends. Review
the selected backend and app gates before authorizing broader work. This is a
reason for a bounded pilot, not evidence that every command is unsafe.

Keep Day One Mac skills in their supported AI clients. Atticus's backend use does
not prove it discovers those skills or native agents automatically. Background
and scheduled capabilities have additional backend requirements; check upstream
before selecting them.

## Verify, recover and remove

1. Test the command with both matching external desks when available.
2. Test cancellation, an absent monitor and several VS Code windows without
   putting unsaved work at risk. Stop if selection is unpredictable.
3. Quit Atticus and confirm Raycast layouts still work independently.

Expected result: voice is an optional convenience, not a dependency for recovery.

Before updating or removing, quit the app and preserve `~/.config/atticus`
privately: it may contain settings and conversation data. Use the app's startup
control to remove login behavior, verify the LaunchAgent status, then remove
only the confirmed owned bundle. Archive the selected `~/.atticus` source if no
longer needed. Keep configuration and signing material until ownership and
recovery requirements are resolved. Avoid broad Library or Keychain cleanup.
Return to the [workspace guide](workspaces.md) if you decline the pilot.
