# Use the setup workspace with GitHub Copilot

Open the private workspace in VS Code and use the Copilot harness with the
installed skills and optional `.github/agents/*.agent.md` definitions. Copilot account access and
organisation policy still apply.

## Prerequisites and steps

1. Complete [bootstrap](../bootstrap.md), then check the existing
   [VS Code setup](../../manual/editors/vscode.md) for account and profile guidance.

   Expected result: Copilot can answer a harmless request in the selected editor.

2. Install the [main skill](../../manual/ai/day-one-skills.md) or export an
   [assistant workspace](../operation.md), then open its directory:

   ```bash
   code "$SETUP_WORKSPACE"
   ```

   Expected result: `.agents/skills/day-one-mac` is available. An exported
   workspace also contains `START.md` and project roles. Review Workspace Trust.

3. Choose Copilot as the session harness. Open **Chat: Open Customizations**
   from the Command Palette and inspect the available agents and skills.

   Expected result: the installed skill and any activated roles are discoverable.
   Menu availability varies with the installed VS Code release and harness.

4. Ask `day-one-mac` for a read-only plan, or select `day-one-planner` if
   activated. After approval, execute the selected scope using normal tool
   confirmations or the optional `day-one-operator` role.

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
