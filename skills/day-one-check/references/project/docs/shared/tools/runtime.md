# Install and manage the optional runtime

Install `day-one-mac` only when you want its reviewed utilities, bundled reader
or assistant export. Manual setup does not require it. The runtime is versioned
under `~/.local/share/day-one-mac` and needs no permanent Git checkout.

## Availability and prerequisites

You need native Apple-silicon macOS in the supported dependency range, network
access and an approved installation location. Follow the shared prerequisites.
New commands described in this source tree may not exist in the latest public
release. Check release notes, `day-one-mac --version` and command help. A source
branch or local commit is not evidence of publication.

## Install a reviewed public release

1. Install Apple's Command Line Tools if missing:

   ```bash
   xcode-select --install
   ```

   Expected result: complete the Apple installer, then `xcode-select -p` prints
   its installation path. If already installed, preserve the existing tools.

2. Download and inspect the release installer:

   ```bash
   INSTALLER="$HOME/Downloads/install-day-one-mac"
   curl --proto '=https' --tlsv1.2 -fsSL \
     https://github.com/CodeByKwakes/day-one-mac/releases/latest/download/install-day-one-mac \
     -o "$INSTALLER"
   less "$INSTALLER"
   ```

   Expected result: a readable installer. Press `q` after review. Do not pipe
   remote code into a shell or disable certificate verification.

3. Run the reviewed installer:

   ```bash
   /bin/bash "$INSTALLER"
   export PATH="$HOME/.local/bin:$PATH"
   day-one-mac runtime-status
   ```

   Expected result: the requested version and verified runtime integrity.
   The installer checks archive checksums and preserves earlier runtime copies.
   A checksum from the publisher detects corruption; it is not independent provenance.

4. Inspect the installed command and open the guides:

   ```bash
   day-one-mac --help
   day-one-mac docs --browser
   ```

   Expected result: available commands and the bundled handbook. Select
   AI-assisted or manual setup. The command does not launch a setup wizard.

For provenance enforcement with an approved GitHub CLI, use the installer's
`--require-attestation` option. This requires network access and a release with
valid repository/workflow attestations. Review the installer itself before
executing it; an archive check cannot authenticate code already running.

## Update and verify

1. Inspect the current version with `day-one-mac runtime-status`.

   Expected result: the active runtime and integrity status.

2. Read the proposed release notes and [migration guide](../migration/from-scripted-setup.md).
   Preserve existing private recovery records and important application data.

   Expected result: a reviewed update and a retained working runtime.

3. Apply the selected public update:

   ```bash
   day-one-mac update
   day-one-mac verify
   ```

   Expected result: the new runtime passes integrity checks. This does not update
   developer applications or prove machine readiness. `update --require-attestation`
   adds the same provenance gate as installation.

4. Re-export an assistant workspace if desired, then verify it before use.

   Expected result: old sessions/customisations remain available for comparison.
   See [assistant operation](../../setup/ai/operation.md).

## Roll back or remove

1. Read `day-one-mac rollback-runtime --help` and run its preview without apply options.

   Expected result: available retained versions and an explicit selection procedure.

2. Choose the required version using that help, then run `day-one-mac runtime-status`.

   Expected result: the selected version is active. Runtime rollback does not
   reverse changes to application data or configuration.

3. To remove only the runtime, inspect `day-one-mac uninstall-runtime --help`
   and its default preview before using the documented execution confirmation.

   Expected result: the launcher/runtime scope is explicit. Configured apps,
   private setup state and recovery records are preserved.

If installation fails, retain the error and previous runtime. Do not delete
state or broaden permissions to force success. For developer-tool removal use
[component lifecycle](../../setup/manual/lifecycle.md).
