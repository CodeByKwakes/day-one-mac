# Read or export the documentation

Open the [Day One Mac handbook](https://codebykwakes.github.io/day-one-mac/) in a
browser. Choose AI-assisted or manual setup, search for a tool, or download the
handbook for offline use. Reading needs no Node.js, setup manager or source checkout.

If the website has not been published yet, read [Start here](../START-HERE.md)
on GitHub or in an extracted source archive. An installed AI skill also contains
the guides under `references/project/docs/`; it does not depend on the website.

## Open the handbook conveniently

1. Open the handbook and bookmark it in your preferred browser.

   Expected result: one bookmark opens the published documentation. Its AI-assisted
   and manual links lead to the same canonical recipes used by installed skills.

2. Search for a topic such as `VS Code`, `Docker` or `backup`. On a keyboard,
   press `/` to focus search when you are not typing in another field. On a small
   screen, choose **Browse guides** to reveal search and chapter navigation.

   Expected result: matching guide titles appear. Select one to read it; a
   missing result leaves the chapter list available.

3. If you want a macOS shortcut, drag the website address from the browser to
   Finder to save an Internet location file, then open that file when needed.
   Browser support for dragging addresses varies; a bookmark works in every case.

   Expected result: the shortcut opens the website in your browser. It does not
   install a Day One Mac command, app manager or background process.

## Download and read offline

1. On the published website, choose **Download offline**.

   Expected result: `day-one-mac-offline.zip` downloads. It contains the same
   documentation snapshot as the website that supplied it.

2. Extract the ZIP using Finder and open `day-one-mac-guide/index.html`.

   Expected result: the handbook opens with search and navigation available
   without a network connection. Links to external services still need internet.

3. Keep the complete `day-one-mac-guide` folder together. Use **Print / save PDF**
   below a guide to print that guide, or share the complete folder to include
   linked examples and templates.

   Expected result: local guide links and attachments remain usable. The offline
   header offers **Reading options** rather than another ZIP download.

4. Download a new copy when you want updated documentation. Compare the revision
   and snapshot shown in the footer, or open `snapshot.json` in each folder.

   Expected result: the old copy remains available until you deliberately remove
   it. Website, offline and installed-skill versions can differ; updating one
   does not update the others or change your Mac's tools.

## Build a reader from source

These are contributor commands. Use a reviewed checkout, Node.js 22.20 or newer
and, for the website ZIP, the `zip` command. macOS supplies `zip`; contributors
on other systems must install it through their own approved package manager.

1. From the repository root, build into a new directory:

   ```bash
   node tools/build-docs-site.cjs --output "$HOME/Downloads/day-one-website-review"
   ```

   Expected result: `index.html`, reviewed public guides, `snapshot.json` and
   `day-one-mac-offline.zip`. Existing destinations are refused. Unlisted files,
   private notes and dependency folders are excluded.

2. Open the new `index.html` in your browser. On macOS:

   ```bash
   open "$HOME/Downloads/day-one-website-review/index.html"
   ```

   Expected result: the website preview opens locally. Test the download, extract
   it and open its separate `index.html` before sharing either output. Local-file
   download behavior varies by browser; the ZIP is also available in Finder.

For a reader without a ZIP, or a Markdown snapshot, keep using the standalone
exporter with a new destination:

```bash
node tools/export-docs.cjs --format html --output "$HOME/Downloads/day-one-reader"
node tools/export-docs.cjs --format markdown --output "$HOME/Downloads/day-one-markdown"
```

Expected result: the selected export is self-contained. Source checkout removal
is safe after export. Builds record a content fingerprint; only builds supplied
with an explicit `--revision` record a Git commit. Do not label modified local
files with a clean commit's revision.

## Publish and update the website

1. Merge reviewed changes into `main` and push them through the normal review
   process. Enable **Repository Settings → Pages → Build and deployment → Source
   → GitHub Actions** once, with the `github-pages` environment restricted to
   `main`.

   Expected result: GitHub Pages is configured to accept the documentation
   workflow. Publishing makes the reviewed public documentation accessible online.

2. Wait for **Actions → Validate** to succeed for the main-branch revision.
   **Publish documentation** then builds and deploys that revision. To retry the
   current revision, run **Actions → Validate → Run workflow → main**.

   Expected result: both workflows succeed. Pull-request runs, failed checks and
   superseded revisions do not publish. No application-release pipeline runs.

3. Open the URL shown by the **github-pages** deployment. Test a direct guide
   link, search, the offline download and its extracted `index.html`.

   Expected result: the website and downloaded `snapshot.json` show the same
   revision and fingerprint. Browser content does not configure the local machine.

4. To roll back, revert the documentation change in a reviewed commit on `main`
   and let validation and publishing run again. Keep a known-good offline copy
   available while a deployment is being repaired.

   Expected result: the previous content returns through a new, validated
   revision. Do not force-push history or restore a retired runtime.

## Troubleshooting

| Symptom | What to check |
|---|---|
| Website returns 404 | Confirm Pages uses GitHub Actions and the first deployment succeeded. Read the repository guides meanwhile. |
| Export destination exists | Choose a new folder. Builds never overwrite an existing reader. |
| Missing or unsafe source | Maintainers review `config/document-sources.txt` and the named file. Do not bypass source checks or add private files. |
| ZIP build fails | Check Node.js and `zip` availability. Inspect retained incomplete output, then retry in a new directory. |
| Clipboard access is blocked | The code is selected instead. Press Command+C to copy; the reader never executes it. |
| A guide is wider than the screen | Scroll within its table or code block; code also offers **Wrap lines**. |
| Local HTML is blocked | Use an approved browser or read the bundled Markdown. A network server is not required. |
| Website or skill looks older | Compare the website footer, offline `snapshot.json` and installed skill revision. Update the selected copy explicitly. |

<a id="read-and-export-documentation-offline"></a>
<a id="browser-walkthrough"></a>
<a id="export-a-durable-copy"></a>
<a id="pdf-and-print"></a>
<a id="command-reference"></a>
<a id="contents-safety-and-cleanup"></a>
<a id="maintainer-notes"></a>
<a id="macos-shortcuts-guide"></a>
<a id="build-an-offline-reader"></a>
