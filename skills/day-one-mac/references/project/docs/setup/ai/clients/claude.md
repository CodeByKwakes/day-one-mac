# Use the setup workspace with Claude Code

Claude Code accesses installed skills through `.claude/skills`. The optional
workspace export also supplies shared instructions through `CLAUDE.md` and
agent definitions in Claude's own format.

## Prerequisites and steps

1. Complete [bootstrap](../bootstrap.md), then install the [main skill](../../manual/ai/day-one-skills.md)
   or export an [assistant workspace](../operation.md).

   Expected result: an approved Claude Code installation and a verified workspace.

2. Open a terminal in that directory and start Claude Code:

   ```bash
   cd "$SETUP_WORKSPACE"
   claude
   ```

   Expected result: a session rooted in the setup workspace. Review any trust prompt.

3. If you activated the optional roles, use `/agents` to inspect `day-one-planner`, `day-one-operator`,
   `day-one-verifier` and `day-one-maintainer`.

   Expected result: the four activated project roles are visible. Without role
   activation, ask the main session to use `day-one-mac` for a read-only plan.

4. Review the plan before approved execution, using the operator if available.

   Expected result: the planner reads files without a shell or editing tool.
   The operator retains normal permission prompts for approved changes.

## Shared files and permission limits

`CLAUDE.md` imports `@AGENTS.md`. The exporter creates the relative link
`.claude/skills -> ../.agents/skills` inside the new workspace. For an existing
project, use the collision-safe [manual procedure](../../manual/ai/day-one-skills.md).
Do not symlink the entire `.claude` directory or copy authentication files.

Planner and verifier definitions list only `Read`, `Glob` and `Grep`. They
inspect evidence; an operator or user supplies command results. Operator and
maintainer definitions use normal permission mode. Parent-session settings can
affect subagent permissions, so do not use bypass mode for setup.

Fields and permission behaviour were checked on 24 October 2026 against
[Claude Code subagent documentation](https://code.claude.com/docs/en/sub-agents).
Confirm account, model and gateway compatibility separately from file discovery.
