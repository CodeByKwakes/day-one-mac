# Build review copies of developer apps

The bundled builder creates selected standalone `.app` files in a new directory.
It does not install them, launch them or change your Shortcuts library. For manual
creation and app lifecycle steps, use the [shortcut guide](../../setup/manual/apps/macos-shortcuts.md#build-standalone-apps-manually).

## Prerequisites and commands

Use native Apple silicon, macOS and Node.js 22.20 or newer. The builder uses the
system AppleScript compiler, property-list tools and ad hoc code signing.
Ad hoc signatures provide local bundle integrity; they are not Developer ID
signatures or notarization. The target apps are needed when running a launcher,
not when compiling it.

From the installed `day-one-shortcuts` directory, list the recipes:

```bash
bash references/project/helpers/shortcuts/build-apps.sh --list
```

Expected result: five recipe IDs and their dependencies. The main `day-one-mac`
package includes the same helper and assets at the same relative paths.

| Option | Default | Usage |
|---|---|---|
| `--help` | Used when no arguments are supplied | Show command syntax without writes |
| `--list` | Off | List recipes; use by itself |
| `--recipe ID` | Required for a preview or build | Choose a catalogue ID or `all` |
| `--output PATH` | Required for a preview or build | New absolute directory outside the source and skill |
| `--build` | Off | Compile the previewed selection into the new directory |

1. Choose a new review directory whose parent already exists:

   ```bash
   SHORTCUT_REVIEW="$HOME/Desktop/Developer Apps Review-$(date +%Y%m%d-%H%M%S)"
   ```

   Expected result: a path variable; no directory is created. Use another
   existing parent if Desktop is unavailable or managed.

2. Preview the selected build:

   ```bash
   bash references/project/helpers/shortcuts/build-apps.sh \
     --recipe all --output "$SHORTCUT_REVIEW"
   ```

   Expected result: app names, dependencies, source hashes and a preview-only
   notice. Existing paths, symlinks and output inside the skill are refused.

3. Review the source and run the same selection with `--build`:

   ```bash
   bash references/project/helpers/shortcuts/build-apps.sh \
     --recipe all --output "$SHORTCUT_REVIEW" --build
   ```

   Expected result: five apps, five combined readable source files and
   `build-manifest.json`. The parent directory is private, with mode `0700`.
   The builder verifies each signature without launching its app.

4. Follow the manual guide's [verification and installation steps](../../setup/manual/apps/macos-shortcuts.md#verify-and-install-the-apps).

   Expected result: each selected app has a functional result recorded separately
   from its successful compilation. Permission prompts remain local decisions.

For one app, replace `all` with its ID, such as `open-vscode-profile`. From a
source checkout, use `bash helpers/shortcuts/build-apps.sh` instead. Both forms
resolve assets relative to the helper, independent of the current directory.

## Failure, update and removal

An interrupted or failed build can leave partial output. `BUILD-INCOMPLETE.txt`
marks a caught failure; a sudden interruption may leave no marker. Absence of
`build-manifest.json` means the build did not finish. Inspect the exact directory
and choose a new output for retry. The builder does not automatically delete it.

Rebuild into a fresh directory for an update. Follow the owning guide to preserve
and replace selected apps. There is no replace or uninstall flag: the helper
never manages an installed app directory. Removing a skill does not remove apps
that were built from it.

The manifest records each recipe ID, app name, bundle identifier and combined
source hash, plus the icon path and hash when a recipe supplies one. Icons
are embedded before signing. It records build provenance, not live functionality or a security
certification. Do not store private notes or generated apps inside an installed
skill because reinstalling the skill can replace its contents.

## Verification limits

The integration fixtures compile all five apps, inspect signatures and exercise
pure handlers for folder validation, URI encoding and existing-profile checks.
Mock commands verify argument boundaries. Tests do not run the interactive app
handlers or modify live VS Code profiles.

Read [the reviewed helper reference](../reference/tools.md) for other bounded
operations. The manual setup route remains independent of this builder.
