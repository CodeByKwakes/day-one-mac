# Read or export the documentation

Read the guides on GitHub, from an extracted source archive or from an installed
skill's `references/project/docs/` directory. Start at `docs/START-HERE.md`.
No Day One Mac runtime, background service or permanent checkout is required.

## Build an offline reader

This is contributor tooling. A user who receives the exported folder only needs
a browser. A maintainer needs a reviewed checkout and Node.js 22.20 or newer.

1. From the repository root, create an export in a new directory:

   ```bash
   node tools/export-docs.cjs --format html --output "$HOME/Downloads/day-one-reader"
   ```

   Expected result: `index.html`, reviewed public guides and linked examples.
   Existing destinations are refused. Private notes and unlisted files are excluded.

2. Open the exported `index.html` in a browser.

   Expected result: search, navigation and guide links work with no server or
   network connection. The source checkout can be removed after export.

3. Use **Print / save PDF** to print the current guide, or share the whole
   exported folder when the recipient needs linked templates and assets.

   Expected result: the recipient can read the guide independently. Keep any
   private session notes outside the shared export.

Use `--format markdown` for an unchanged Markdown snapshot. Exports record a
content fingerprint, not a runtime version. Rebuild from the newly reviewed Git
revision to update a reader; retain the previous folder until verified.

## Troubleshooting

If export reports a missing or unsafe source, maintainers review
`config/document-sources.txt` and the source file. Do not bypass symlink checks or
add private files. If a browser blocks local opening, use an approved browser or
read the Markdown files; enabling a network server is not required.

<a id="read-and-export-documentation-offline"></a>
<a id="browser-walkthrough"></a>
<a id="export-a-durable-copy"></a>
<a id="pdf-and-print"></a>
<a id="command-reference"></a>
<a id="contents-safety-and-cleanup"></a>
<a id="maintainer-notes"></a>
<a id="macos-shortcuts-guide"></a>
