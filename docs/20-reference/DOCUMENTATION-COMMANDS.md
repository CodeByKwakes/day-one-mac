[← Reference library](README.md) · [Manual handbook](../manual/README.md)

# Read and export documentation offline

**Document type:** how-to and command reference. **Audience:** users of an
installed release and contributors checking a source checkout.

## Browser walkthrough

```bash
day-one-mac docs handbook --browser
day-one-mac docs chezmoi-guide --browser
```

The command creates a private temporary reader and opens it in your default
browser. No server, network download, Node.js installation, or Python
installation is required. JavaScript must be enabled in the browser; it renders
only the bundled Markdown. Use the navigation, title/path search and guide links
to move around. External links require a connection only if you follow them.

The header shows the bundled `VERSION`, not the newest published release. A
source checkout can contain uncommitted changes under that same version; the
label is not release provenance. The source path is printed above each guide.
No command in a code block runs when you view, search or print it.

## Export a durable copy

Choose a new directory under an existing parent:

```bash
day-one-mac docs export --format html --output ./day-one-docs
day-one-mac docs export --format markdown --output ./day-one-markdown
```

Open `index.html` in the HTML export. Move or share the whole export folder so
its Markdown files and bundled examples remain together. HTML links between
guides stay inside the reader; Markdown links retain their relative paths.

The exporter refuses an existing output directory, even if empty, and never
overwrites a previous export. Choose another name when exporting a new version.
Exports inside a checksummed installed runtime are also refused to preserve
its exact file inventory.
An interrupted export can leave a partial new directory: discard that specific
directory after inspection and retry with a fresh name.

## PDF and print

Open the required guide and select **Print / save PDF**. The browser's print
dialog can save that guide as a PDF. Navigation and search controls are hidden
in print; the version and document path remain visible.

This prints the **current guide only**, not the whole handbook or every linked
document. There is no `--format pdf` exporter. Use the HTML folder for a complete
offline library, or print the individual guides you need.

## Command reference

| Command | Result |
|---|---|
| `docs [TOPIC]` | Print the original Markdown path; defaults to `start` |
| `docs [TOPIC] --open` | Open Markdown in its default application; unchanged compatibility behaviour |
| `docs [TOPIC] --browser` | Open a temporary offline HTML reader at that topic |
| `docs --list` | List topics and original paths |
| `docs --folder --open` | Open the bundled documentation directory |
| `docs export --format html --output NEW_DIRECTORY` | Export reader, Markdown and bundled examples |
| `docs export --format markdown --output NEW_DIRECTORY` | Export Markdown and bundled examples without the reader |

`--browser` cannot be combined with `--open`, `--list` or `--folder`. Export
requires both `--format` and `--output`; only `html` and `markdown` are accepted.

Existing topics keep their meaning: `manual` is the complete manual setup guide,
and `chezmoi` is the setup tutorial. New topics are `handbook`, `chezmoi-guide`,
`chezmoi-daily`, `chezmoi-reference`, and `chezmoi-concepts`. The handbook brings
manual tasks together without breaking older commands or guide links.

## Contents, safety and cleanup

Exports select documentation and examples from the explicit runtime allowlist:
`docs/`, `second-brain/`, `warp-drive/`, and the bundled root README, contributor
guide, changelog, security policy, licence and version. They do not recursively
scan your checkout or home folder. Symlinked input files or parent directories
are rejected. Unlisted files, personal dotfiles, setup state, logs, acceptance
records and credentials are not included.

In a source checkout, listed documents are exported as they currently exist.
Review local edits before sharing an export; the allowlist is not a secret
scanner. Installed bundles do not pull newer documentation automatically.

Raw HTML in Markdown is displayed as text. Embedded images are replaced with
their text descriptions, so no tracking pixels or remote assets load. Tables,
code blocks, headings and links render locally; syntax highlighting and diagram
execution are intentionally absent. External links are still your decision.

Browser previews live in the printed `day-one-mac-docs.*` temporary directory.
Close their browser tabs before removing those specific temporary folders.
Durable exports can be moved to Trash when no longer needed. Neither action
changes the runtime, chezmoi source or setup completion records.

## Maintainer notes

`scripts/docs.sh` selects files and builds the offline bundle.
`scripts/lib/docs-browser.*` implement presentation and navigation. The vendored
Markdown renderer and its MIT licence are in `scripts/vendor/markdown-it/`.
No runtime package install is needed. Update the explicit runtime allowlist
whenever adding a bundled guide or reader asset; run `scripts/tests/test-docs.sh`,
Markdown lint, full validation, and packaged-runtime checks before release.
