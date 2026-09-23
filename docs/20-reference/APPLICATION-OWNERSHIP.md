[Project home](../README.md) · [Start here](../START-HERE.md) · [Rollback](../04-operations/ROLLBACK.md)

# Application ownership: Homebrew, Company Portal, or another installer

Day One Mac checks whether an application already works **before** asking
Homebrew to install it. This makes the same setup usable on:

- a personal Mac where Homebrew owns most applications; and
- a work Mac where Company Portal, an administrator, or the Mac App Store
  supplied some applications.

An **owner** here means the installer responsible for upgrading and removing
the application. It does not mean the application account or software licence.

## What the check reports

| Result | Plain-English meaning | What Day One Mac does |
|---|---|---|
| Homebrew-managed | The cask appears in `brew list --cask`, and its app, command, or font exists | Keeps it; does not reinstall it |
| Mac App Store | A valid app contains an App Store receipt and Homebrew does not own it | Keeps it and leaves updates to the App Store |
| External installation | The expected app, command, or font exists but Homebrew does not own it | Keeps it; never adds it to Homebrew or the rollback manifest |
| Missing | No valid installation was found | Asks whether to use Homebrew, another approved installer, or stop safely |
| Needs review | An app has the wrong identity, or Homebrew has a receipt but its expected payload is missing | Stops before installing over the conflict |

“External installation” may mean Company Portal, a signed company package, a
manual download, or another approved system. macOS does not always expose a
reliable link from an application back to Company Portal, so the runner does
not pretend to know more than it can verify.

## When the checks happen

1. The setup wizard shows a read-only ownership summary before saving choices.
2. The required Installation Centre checks all required apps together, offers
   one batch Homebrew choice or an item-by-item review, and installs the
   selected track/stack formulae.
3. Phase 3 rechecks 1Password and its CLI before security configuration.
4. Phase 4 rechecks the font, Raycast, VS Code, Warp, and required formulae
   before Git and hosting configuration.
5. Phase 7 rechecks VS Code before configuring its settings and launcher.
6. Phase 8 rechecks every required application and records its source in the
   final verification report.
7. Optional application commands use the same choice and recheck flow before installing
   OrbStack, Obsidian, Claude Code, Codex, the GitHub Copilot app, or GitHub Copilot CLI.

The application version is reported for normal `.app` bundles, but an ordinary
version update does not transfer ownership to Homebrew.

## Run the check yourself

The recommended form works from any directory once the early installer has run:

```bash
day-one-mac applications --required
day-one-mac applications --optional
```

If the portable command is unavailable, use the project scripts directly:

```bash
day-one-mac applications --required
day-one-mac applications --optional
```

Install or revalidate the complete required set after Phase 2:

```bash
day-one-mac install
# Direct fallback:
day-one-mac install
```

Check one optional application and offer to install it only when missing:

```bash
day-one-mac applications --id orbstack --install-missing
day-one-mac applications --id codex --install-missing
```

For every missing item, the command offers three choices:

1. install the listed cask with Homebrew;
2. use Company Portal, the App Store, or another approved installer, then press
   Enter to recheck and continue; or
3. stop safely and resume later.

The second choice keeps the command open while the graphical or company-managed
installer runs. After pressing Enter, Day One Mac clears the shell's command
cache, checks the application again, and continues only when the expected app,
command, or font is available. You can switch to Homebrew or stop safely from
the same prompt. The command has no uninstall mode.

For automation, choose an explicit policy:

```bash
day-one-mac applications --id orbstack --install-missing \
  --app-install-policy homebrew
day-one-mac applications --required --install-missing \
  --app-install-policy check-only
```

`prompt` is the interactive default. `homebrew` installs missing selected
applications without asking which owner to use. `check-only` reports missing
items and changes nothing. A non-interactive run defaults to `check-only`; the
ordinary `--yes` flag does not silently choose Homebrew ownership.

## Required and optional selections behave differently

Required applications are locked in the base setup. A valid external copy
satisfies the requirement; “required” does not mean “Homebrew must own it.”

Optional applications are installed only after explicit selection. If an
optional app already exists externally, selecting it accepts that copy. If the
app is not selected, Day One Mac leaves it alone. Deselecting never means
uninstalling.

Use the application's company portal, App Store, vendor uninstaller, Homebrew,
or the reviewed cleanup guide to remove software through its actual owner.

## Reports and rollback

Every checked catalogue entry is updated in:

```text
~/.day-one-mac/application-provenance.md
~/.day-one-mac/application-provenance.tsv
```

The Markdown file is the readable report. The TSV file is suitable for scripts
or spreadsheets. Both show whether Day One Mac installed the cask and whether
the precise recorded rollback may remove it.

Only a cask actually installed by Day One Mac is added to
`install-manifest.tsv`. An external or pre-existing Homebrew installation is
preserved by the precise rollback. The separate broad cleanup tool can remove
all Homebrew casks, so always read its preview before approving it.

## If an application needs review

Do not delete or reinstall it immediately. Read the displayed reason and check:

```bash
brew list --cask
ls -ld /Applications/*.app
day-one-mac applications --id APPLICATION_ID
```

Common causes are a Homebrew cask whose app was moved or deleted, a different
edition using the expected filename, or a command that is installed but not on
`PATH`. On a managed work Mac, use the company support process before changing
an application supplied by the organisation.

---

[Project home](../README.md) · [Required Installation Centre](../01-required/INSTALLATION-CENTRE.md)
