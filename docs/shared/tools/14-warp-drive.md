# Import the Warp workflow bundle

Use this optional utility after [setting up Warp manually](../../setup/manual/terminals/warp.md).
It exports 63 workflows; it does not install them into Warp or change your cloud workspace.

## Prerequisites

Install the [optional utility bundle](runtime.md) and Warp. Each workflow also
needs the tools it names, such as Git, Homebrew, ghq or a provider CLI. Import only
workflows you intend to use. Keep personal or organisation data out of shared folders.

## Steps

1. Preview the export.

   ```bash
   day-one-mac tool --module 14 --plan
   ```

   Expected result: the source, output scope and manual import boundary.

2. Create the versioned export after reviewing the plan.

   ```bash
   day-one-mac tool --module 14 --apply --yes
   ```

   Expected result: a printed artifact directory. Existing exports remain available.

3. Verify the export.

   ```bash
   day-one-mac tool --module 14 --check
   ```

   Expected result: verified export integrity. This does not prove that Warp imported it.

4. Open Warp's Drive panel, choose the intended workspace and use its folder import
   action to import the exported `Day One Mac` directory. Labels may differ by Warp version.

   Expected result: the command catalogue and seven workflow folders appear.

5. Inspect and run the **Runtime status** workflow.

   Expected result: the selected runtime version and integrity status. If the launcher
   is missing, open a new terminal and verify `command -v day-one-mac`.

## Updates and recovery

Review a new export before importing it. Existing imported workflows do not update
automatically; remove old wizard and broad-cleanup entries from Warp. Keep custom
workflows separately and export them before replacing an import. Removing an
imported folder does not uninstall software or remove the runtime.

Never add a one-click workflow containing destructive `--execute` actions. Inspect
the complete command, selected account and current directory before approving it.
