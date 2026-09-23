[← Stage 0 home](README.md) · [Next: create the safety report →](01-private-inventory.md)

# Choose Route A or Route B

Choose the final result before removing anything. If you are unsure, choose
**Not sure** in the wizard. It creates the safety report and makes no other
change.

## Route A — erase the Mac and start with a blank account

Choose Route A when you want the cleanest possible starting point. Apple's
**Erase All Content and Settings** removes the current user accounts, files,
applications, settings, and credentials while keeping macOS installed.

Route A is usually right when:

- the Mac will be reassigned or sold;
- you want the same experience as setting up a new Mac;
- unexplained background software or settings must not remain; or
- you do not need to preserve the current user account.

The Day One script does **not** perform the erase. After the safety-report and
backup checks, it shows the correct System Settings location and stops.

On macOS 26 or later, a repaired—or possibly repaired—Apple-silicon Mac must
also have no unfinished Repair Assistant work. The wizard asks for this
confirmation before it unlocks Apple's erase handoff. If you are unsure, open
Repair Assistant and finish any reported action first.

## Route B — keep the account and clean developer tools

Choose Route B when you need to keep this macOS user account and applications
that were not installed through Homebrew.

Route B can:

- record installed applications and developer tools;
- archive known shell, Git, package-manager, editor, container, hosting, and AI
  configuration;
- remove every Homebrew formula and cask, then Homebrew itself; and
- optionally archive `~/Developer`, local container data, local 1Password app
  data, and detected SSH private-key files.

Route B does **not** create a blank account. Manually installed applications,
unknown vendor data, macOS preferences, iCloud state, privacy permissions,
login items, and Apple system components can remain.

## Quick comparison

| Question | Route A | Route B |
|---|---|---|
| Keep the current user account? | No | Yes |
| Keep non-Homebrew applications? | No | Yes |
| Remove unknown settings? | Usually yes | Not guaranteed |
| Performed by this script? | No; Apple controls it | Yes, after preview and safety checks |
| Safety report first? | Yes | Yes |
| External backup and restore test first? | Yes | Yes |

## Why the report comes before the route action

The safety report finds risks that are easy to miss, especially:

- a Git repository with uncommitted changes, labelled `DIRTY`;
- a repository with no configured remote copy, labelled `NO-REMOTE`;
- local Docker or OrbStack data;
- manually installed applications and their settings; and
- configuration folders that are not managed by chezmoi.

It does not copy any of these items. Use its findings to decide what the backup
must contain. If the drive is not ready, follow the
[encrypted backup-drive guide](ENCRYPTED-BACKUP-DRIVE.md); the wizard's Step 2
then verifies it, creates or selects the backup folder, and copies the report.
For Route B, Step 3 creates the actual copy-only development snapshot from the
scope you select.

The guided dashboard uses these symbols:

- `✓` completed and revalidated;
- `○` ready to run next;
- `⚠` a copy exists but the restore still needs confirmation; and
- `🔒` a required earlier check is incomplete.

The menu remains open after report, backup, and preview work. If you exit, run
the same command later; it loads the saved paths and checks them again rather
than asking you to remember where you stopped.

## Decision check

Do not continue to an erase or applied cleanup until every relevant statement
is true:

- [ ] I created and reviewed the safety report.
- [ ] I understand that the report is not a backup.
- [ ] Important data is on an encrypted external backup.
- [ ] I restored a few sample items successfully.
- [ ] For Route A, I confirmed that Repair Assistant has no unfinished repair.
- [ ] Every `DIRTY` or `NO-REMOTE` repository has a recovery plan.
- [ ] I understand what my chosen route will keep and remove.

Start or return to the wizard:

```bash
cd "$(day-one-mac root)/scripts"
./prepare-existing-mac.sh --guided
```

---

[← Stage 0 home](README.md) · [Next: create the safety report →](01-private-inventory.md)
