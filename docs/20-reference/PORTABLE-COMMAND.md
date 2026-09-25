[← Command reference](COMMAND-REFERENCE.md) · [Start here](../START-HERE.md)

# Install and manage the standalone runtime

The portable `day-one-mac` command is fully independent of a Git checkout.
It uses a small launcher in `~/.local/bin` and a checksum-verified, versioned
runtime in `~/.local/share/day-one-mac`.

Deleting a source checkout does not remove the runtime, setup state, installed
applications, dotfiles or documentation.

## Recommended installation — no clone

Apple's Command Line Tools must be installed first:

```bash
xcode-select --install
```

After the Apple installer finishes, download the public installer. Do not pipe
remote code directly into a shell:

```bash
INSTALLER="$HOME/Downloads/install-day-one-mac"
curl --proto '=https' --tlsv1.2 -fsSL \
  https://github.com/CodeByKwakes/day-one-mac/releases/latest/download/install-day-one-mac \
  -o "$INSTALLER"
chmod 700 "$INSTALLER"
less "$INSTALLER"
```

Read the file, press `q`, then install:

```bash
"$INSTALLER"
export PATH="$HOME/.local/bin:$PATH"
day-one-mac runtime-status
day-one-mac --wizard
```

The installer:

1. Downloads `day-one-mac-runtime.tar.gz` from the latest GitHub release.
2. Downloads its SHA-256 file separately.
3. Refuses to extract the archive when verification fails.
4. Installs it under `~/.local/share/day-one-mac/releases/<version>`.
5. Replaces the `current` link itself only after the new runtime is ready, then
   verifies that it resolves to the requested version.
6. Installs `~/.local/bin/day-one-mac`.
7. Records `~/.day-one-mac/runtime-root`.
8. Leaves earlier releases available for reviewed rollback.

## Installed layout

```text
~/.local/bin/day-one-mac

~/.local/share/day-one-mac/
├── current -> releases/<version>
└── releases/
    └── <version>/
        ├── scripts/
        ├── config/
        ├── docs/
        ├── second-brain/
        ├── warp-drive/
        ├── VERSION
        └── SHA256SUMS

~/.day-one-mac/
├── runtime-root
├── completed/
├── verification.md
└── setup state and recovery manifests
```

The chezmoi source remains independent at `~/.local/share/chezmoi`.

## Verify the runtime

```bash
command -v day-one-mac
day-one-mac root
day-one-mac runtime-status
day-one-mac docs
day-one-mac setup --status
```

Expected results:

- command: `~/.local/bin/day-one-mac`;
- root: `~/.local/share/day-one-mac/current`;
- mode: `standalone runtime`;
- integrity: `verified`.

List the installed guides, open one by topic, or reveal the complete
documentation folder:

```bash
day-one-mac docs --list
day-one-mac docs start --open
day-one-mac docs manual --open
day-one-mac docs chezmoi --open
day-one-mac docs --folder --open
```

Without `--open`, the command prints the installed path. This is useful when
opening a guide in a specific editor, for example:

```bash
code "$(day-one-mac docs commands)"
```

## Move an already-completed Mac to standalone mode

If Phases 1–8 were completed before the standalone runtime was installed, do
not reset progress or rerun the first-time choices. Read
[Upgrade notes](UPGRADE-NOTES.md), download the current public installer as
shown above, then run:

```bash
"$INSTALLER" --update
export PATH="$HOME/.local/bin:$PATH"
hash -r
day-one-mac runtime-status
day-one-mac root
day-one-mac --guided
```

The installer preserves `~/.day-one-mac`, the completed phase fingerprints,
chezmoi source, dotfiles and installed applications. The guided run revalidates
saved completions and skips phases that remain current. `runtime-status` must
report `standalone runtime` and `Integrity: verified`; `root` should normally
point below `~/.local/share/day-one-mac`, not a personal Git checkout.

After verification, continue directly to optional work when wanted:

```bash
day-one-mac optional --guided
day-one-mac databases --saved    # when Databases was selected
```

## Update safely

```bash
day-one-mac update
day-one-mac runtime-status
day-one-mac validate
```

An update installs a new version beside the existing version. It does not
overwrite the previous release in place. The command fails rather than reports
success if `current` does not resolve to the downloaded version. Phase 5 keeps
the launcher out of chezmoi so applying dotfiles cannot reverse the runtime
switch.

## Roll back the runtime

Preview the available previous runtime:

```bash
day-one-mac rollback-runtime
```

Switch only after reviewing the version:

```bash
day-one-mac rollback-runtime --execute
```

Choose an exact installed version when necessary:

```bash
day-one-mac rollback-runtime --version <installed-version> --execute
```

This changes only the Day One Mac runtime. It does not reverse applications,
dotfiles or macOS settings changed by a setup phase.

## Install from a source checkout

Contributors can clone the public repository:

```bash
mkdir -p "$HOME/Developer/github.com/CodeByKwakes"
git clone https://github.com/CodeByKwakes/day-one-mac.git \
  "$HOME/Developer/github.com/CodeByKwakes/day-one-mac"

"$HOME/Developer/github.com/CodeByKwakes/day-one-mac/scripts/install-portable-command.sh" \
  --standalone
```

The checkout may be removed after `day-one-mac runtime-status` reports
`Integrity: verified`.

Repository contributors may deliberately use linked development mode:

```bash
./scripts/install-portable-command.sh --linked
```

Linked mode depends on that checkout and is not recommended for a normal Mac
setup.

## Install an offline archive

Keep these two release assets together:

```text
day-one-mac-runtime.tar.gz
day-one-mac-runtime.tar.gz.sha256
```

Then run:

```bash
./install-day-one-mac --archive "$HOME/Downloads/day-one-mac-runtime.tar.gz"
```

## Remove only the runtime

Preview:

```bash
day-one-mac uninstall-runtime
```

Execute after reviewing:

```bash
day-one-mac uninstall-runtime --execute
```

This removes:

```text
~/.local/bin/day-one-mac
~/.local/share/day-one-mac
~/.day-one-mac/runtime-root
```

It preserves `~/.day-one-mac`, installed software, dotfiles, projects and
macOS settings. Use the documented removal or rollback workflow when you want
to reverse setup changes rather than merely remove the runtime.

---

[Continue with Start here →](../START-HERE.md)
