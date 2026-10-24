# Use the setup workspace with Codex

Use the shared skills and project agent files in a private workspace. Codex
account access and permissions belong to the parent session.

## Prerequisites and steps

1. Complete [bootstrap](../bootstrap.md), then install the [main skill](../../manual/ai/day-one-skills.md)
   or export an [assistant workspace](../operation.md).

   Expected result: an approved Codex installation and a verified directory.

2. Open that directory in the Codex app, or start the CLI there:

   ```bash
   cd "$SETUP_WORKSPACE"
   codex --sandbox read-only
   ```

   Expected result: a read-only planning session rooted in the setup workspace.
   Check your installed CLI help if a managed client restricts this option.

3. Ask Codex to follow any project instructions and use `$day-one-mac` for a plan.
   If you installed only a specialist, use its name instead. Request
   `day-one-planner` only if you activated the optional project roles.

   Expected result: the plan cites the bundled guides and makes no changes.

4. After approving the plan, start an execution session using normal approval
   controls and request `day-one-operator`. Keep workspace access scoped; approve
   specific changes outside it when needed. Do not enable unrestricted access.

   Expected result: approved operations produce evidence and unresolved human steps.

## Agent and permission limits

The templates use standalone `.codex/agents/*.toml` files with `name`,
`description` and `developer_instructions`. Model selection inherits the session.
These files cannot override the parent's sandbox, approval policy or provider.
The planner and verifier's instructions request read-only behaviour; the parent
read-only session enforces filesystem restrictions.

If your client does not discover these files, use the skills in the main session
and follow the same roles explicitly. Do not translate Claude YAML into Codex TOML.

Schema checked on 24 October 2026 against
[official custom agent documentation](https://learn.chatgpt.com/docs/agent-configuration/subagents).
Actual discovery depends on the installed client and workspace policy; verify it
with a harmless planning request before granting execution access.
