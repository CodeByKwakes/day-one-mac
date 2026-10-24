# Use the setup workspace with GitHub Copilot

Open the private workspace in VS Code and use the Copilot harness with the
bundled `.github/agents/*.agent.md` definitions. Copilot account access and
organisation policy still apply.

## Prerequisites and steps

1. Complete [bootstrap](../bootstrap.md), then check the existing
   [VS Code setup](../../manual/editors/vscode.md) for account and profile guidance.

   Expected result: Copilot can answer a harmless request in the selected editor.

2. Open the prepared workspace:

   ```bash
   code "$SETUP_WORKSPACE"
   ```

   Expected result: `START.md`, `.agents/skills` and `.github/agents` are visible
   in the workspace. Review Workspace Trust before enabling execution.

3. Choose Copilot as the session harness. Open **Chat: Open Customizations**
   from the Command Palette and inspect the available agents and skills.

   Expected result: the Day One roles and shared skills are discoverable.
   Menu availability varies with the installed VS Code release and harness.

4. Select `day-one-planner` and ask for a plan. After approving it, select
   `day-one-operator` for the bounded execution scope.

   Expected result: the planner has read/search tools only. Operator execution
   remains subject to the editor's normal tool approvals and organisation policy.

## Verification and limitations

The verifier uses read/search tools and reviews evidence supplied by the
operator. Keep global tool auto-approval disabled. A successful model response
is not proof that shell execution or a gateway connection is supported.

Native `.agents/skills` discovery and `.github/agents` customisation were checked
on 24 October 2026 against the official
[skills guide](https://code.visualstudio.com/docs/agent-customization/agent-skills)
and [agent guide](https://code.visualstudio.com/docs/agent-customization/custom-agents).
If a harness does not load the roles, attach the relevant skill and guide to a
planning conversation rather than assuming it has the missing configuration.
