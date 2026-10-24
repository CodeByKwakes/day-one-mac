# Migrate from scripted setup

The setup runner and optional runtime are retired. Existing developer tools,
settings and recovery backups remain useful; do not reinstall them merely to
change setup routes.

1. Inspect the current Mac and preserve working configuration and private backups.

   Expected result: you know what is installed and who owns each selected tool.

2. Follow [legacy manager removal](remove-legacy-manager.md) to inspect and
   retire the old launcher, runtime and dependent integrations.

   Expected result: only explicitly approved manager-owned items move to a
   verified private archive. State and ownership records remain recoverable.

3. Choose [AI-assisted setup](../../setup/ai/README.md) or
   [manual setup](../../setup/manual/README.md).

   Expected result: fresh checks determine the next task. Old phase markers
   never establish current readiness.

4. Install the [portable skill](../../setup/manual/ai/day-one-skills.md) if using AI.

   Expected result: the client discovers the skill without a global Day One Mac
   command. Use scoped skill updates instead of runtime updates.

There are no replacement command wrappers or automatic runtime upgrades. Keep
historical recovery records until their owner decides they are no longer needed.

<a id="before-updating"></a>
<a id="choose-the-new-journey"></a>
<a id="retired-commands-and-recovery"></a>
