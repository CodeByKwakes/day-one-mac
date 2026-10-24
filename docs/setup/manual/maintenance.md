# Maintain the environment

Update one ownership layer at a time, with a tested backup and a working project
check. Use Homebrew only for packages it owns; Company Portal, App Store and
manual installations keep their own update channels.

## 1. Inspect Homebrew metadata

Run `brew update`.

Expected result: current package metadata, or a specific network error to resolve.
This does not upgrade all installed software.

## 2. Review available changes

Run `brew outdated`.

Expected result: a list of upgrade candidates, possibly empty. Review release
notes and project constraints before selecting a package.

## 3. Upgrade a selected package

Run `brew upgrade PACKAGE`, replacing `PACKAGE` with the reviewed formula or
cask. Use `--formula` or `--cask` when the token is ambiguous.

Expected result: that selected package upgrades. Recheck its version and one
real workflow before updating another dependency layer.

## 4. Review cleanup separately

Run `brew cleanup --dry-run`.

Expected result: proposed cache/old-version removals only. Run `brew cleanup`
only after reviewing the list and confirming those retained versions are no
longer needed. Cleanup is not a backup or a database reset.

## Useful inspection combinations

```bash
brew update && brew outdated
```

The second command runs only if metadata refresh succeeds. To inspect installed
packages by ownership class, run `brew list --formula` and `brew list --cask`
separately. Use `brew info PACKAGE` to inspect a specific item and
`brew services list` to inspect Homebrew services. Do not start or stop a service
until you have identified its data and owner.

## Troubleshooting and recovery

Use `brew doctor` to investigate a package-manager problem and act on the exact
reported path. A previous version may no longer be available upstream; confirm
recovery before an important upgrade. Keep project lockfiles, runtime pins and
database backups independent of package-manager cleanup.

For shell/editor problems, restore the reviewed configuration through its owner.
For service problems, use the [database operations guide](databases/operations.md).
