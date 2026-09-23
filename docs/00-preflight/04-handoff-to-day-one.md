[← Route B cleanup](03-account-preserving-cleanup.md) · [Start Day One Phase 1 →](../01-required/01-first-boot-and-decisions.md)

# Continue to Day One Mac

Use the checklist for your chosen route. The eight required Day One phases
start only after the old state is safely handled.

## Route A — after Apple reset

- [ ] Apple's Setup Assistant finished with the intended new account.
- [ ] The Mac is connected to power and a trusted network.
- [ ] The encrypted backup is disconnected except during an intentional restore.
- [ ] Old files and settings will be restored selectively, not by copying the
      entire old home folder.

This is the cleanest Day One boundary. Continue directly to Phase 1.

## Route B — after account-preserving cleanup

- [ ] The Terminal ended with `development cleanup complete`.
- [ ] The printed recovery folder exists on the encrypted external drive.
- [ ] `cleanup.log`, `settings-scope.md`, and `README.md` are readable.
- [ ] Homebrew is gone, unless a reported cask failure deliberately preserved it.
- [ ] I understand that unknown user and application settings can remain.

Restart the Mac before Phase 1. This closes old background processes and shell
sessions. Disconnect the recovery drive during normal setup; reconnect it only
when restoring a specific reviewed item.

If `~/Developer` was archived, first restore or reclone this repository to:

```text
~/Developer/github.com/CodeByKwakes/day-one-mac
```

Do not copy the entire archived development configuration back. That would
recreate the state Route B removed.

## Start the eight required phases

```bash
cd "$(day-one-mac root)/scripts"
./bootstrap-day-one-mac.sh --wizard
```

Choose **New or factory-reset Mac** when Route A completed. After Route B,
choose the same option because the old-state preparation is now finished and
you are ready for Phase 1.

The setup wizard collects the hosting track, language stack, Git identity,
dotfiles source, and optional future plan. Stage 0 does not mark any of Phases
1–8 complete. After Phase 2 prepares Homebrew, the required Installation
Centre installs or accepts all required applications and Terminal tools before
the configuration phases begin.

---

[← Route B cleanup](03-account-preserving-cleanup.md) · [Start Day One Phase 1 →](../01-required/01-first-boot-and-decisions.md)
