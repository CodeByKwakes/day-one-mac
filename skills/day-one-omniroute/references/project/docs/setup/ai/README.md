# AI-assisted setup

Prepare one approved AI client before asking it to set up the Mac. The assistant
uses the canonical manual recipes and reports actual verification results.
Choose guidance only when you want to run the commands yourself.

## Objective and prerequisites

Complete the [shared prerequisites](../../shared/prerequisites.md) and
[decisions](../../shared/decisions.md). You need an approved account, network
access and permission to use the selected client. A subscription or installed
extension does not guarantee access to every model or tool.

## Follow the setup journey

1. Complete [client and connection bootstrap](bootstrap.md).

   Expected result: one working client, an explicit direct-provider or OmniRoute
   choice and a successful harmless request.

2. Install the [main skill](../manual/ai/day-one-skills.md), or prepare the
   optional [assistant workspace](operation.md#prepare-a-workspace).

   Expected result: the main skill and bundled references are available in a
   private directory. Native role definitions are optional with skill installation.

3. Follow the selected client guide: [Codex](clients/codex.md),
   [Claude Code](clients/claude.md) or [GitHub Copilot](clients/copilot.md).

   Expected result: you can identify the loaded skill and role, and understand
   which permissions the parent session grants.

4. Ask for a plan covering only the capabilities in your worksheet.

   Expected result: exact commands, affected files, prerequisites, human steps
   and recovery are visible before you approve changes.

5. Follow [operation and resumption](operation.md) to execute and verify it.

   Expected result: each selected capability has fresh evidence or a clearly
   stated unresolved step. No old phase marker is treated as a successful check.

## Maintenance and fallback

Use [lifecycle guidance](../manual/lifecycle.md) for installing, updating,
removing and recovering individual components. If AI access fails, continue
with the owning [manual guide](../manual/README.md). Preserve the private notes
so another session can resume without repeating successful work.
