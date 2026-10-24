# Prepare Day One Mac skills and agents manually

Copy reviewed, versioned project assets into a new private workspace. This
procedure does not invoke Day One Mac scripts or modify global client settings.
A skill contains instructions; an agent assigns a role within a client's permissions.

## Prerequisites and source

Obtain a reviewed source archive containing `templates/skills`,
`templates/agents` and `templates/setup-assistant`. Use a release that includes
these assets; do not assume an older public release has them. Extract it in
Finder, open Terminal in the extracted directory, and read its source/provenance.
Never copy client authentication files into the workspace.

## Create the workspace

1. Record the extracted source path and choose a new private destination:

   ```bash
   DAY_ONE_SOURCE="$(pwd -P)"
   DAY_ONE_WORKSPACE="$HOME/Developer/Setup/manual-$(date +%Y%m%d-%H%M%S)"
   test -f "$DAY_ONE_SOURCE/templates/skills/day-one-setup/SKILL.md"
   ```

   Expected result: `test` succeeds without output. Stop if it fails; you are in
   the wrong directory or the archive lacks the approved assets.

2. Copy the reviewed files into the new workspace:

   ```bash
   (
     set -euo pipefail
     umask 077
     mkdir -p "$(dirname "$DAY_ONE_WORKSPACE")"
     mkdir "$DAY_ONE_WORKSPACE"
     cp -R "$DAY_ONE_SOURCE/docs" "$DAY_ONE_WORKSPACE/docs"
     cp -R "$DAY_ONE_SOURCE/config" "$DAY_ONE_WORKSPACE/config"
     cp "$DAY_ONE_SOURCE/README.md" "$DAY_ONE_SOURCE/CONTRIBUTING.md" "$DAY_ONE_WORKSPACE/"
     mkdir "$DAY_ONE_WORKSPACE/templates"
     cp -R "$DAY_ONE_SOURCE/templates/phase-05-shell-files" \
       "$DAY_ONE_WORKSPACE/templates/phase-05-shell-files"
     mkdir -p "$DAY_ONE_WORKSPACE/.agents" "$DAY_ONE_WORKSPACE/.codex" \
       "$DAY_ONE_WORKSPACE/.claude" "$DAY_ONE_WORKSPACE/.github" \
       "$DAY_ONE_WORKSPACE/session"
     cp -R "$DAY_ONE_SOURCE/templates/skills" "$DAY_ONE_WORKSPACE/.agents/skills"
     cp -R "$DAY_ONE_SOURCE/templates/agents/codex" "$DAY_ONE_WORKSPACE/.codex/agents"
     cp -R "$DAY_ONE_SOURCE/templates/agents/claude" "$DAY_ONE_WORKSPACE/.claude/agents"
     cp -R "$DAY_ONE_SOURCE/templates/agents/copilot" "$DAY_ONE_WORKSPACE/.github/agents"
     cp "$DAY_ONE_SOURCE/templates/setup-assistant/AGENTS.md" "$DAY_ONE_WORKSPACE/AGENTS.md"
     cp "$DAY_ONE_SOURCE/templates/setup-assistant/CLAUDE.md" "$DAY_ONE_WORKSPACE/CLAUDE.md"
     cp "$DAY_ONE_SOURCE/templates/setup-assistant/START.md" "$DAY_ONE_WORKSPACE/START.md"
     cp "$DAY_ONE_SOURCE/templates/setup-assistant/.github/copilot-instructions.md" \
       "$DAY_ONE_WORKSPACE/.github/copilot-instructions.md"
     ln -s ../.agents/skills "$DAY_ONE_WORKSPACE/.claude/skills"
   )
   ```

   Expected result: a new workspace with shared skills and four roles per client.
   An existing destination stops the procedure. Review any incomplete directory
   before retrying with a new destination. Manual copies do not have the optional
   exporter's integrity manifest.

3. Verify the shared skill and Claude link:

   ```bash
   test -f "$DAY_ONE_WORKSPACE/.agents/skills/day-one-setup/SKILL.md"
   readlink "$DAY_ONE_WORKSPACE/.claude/skills"
   ```

   Expected result: the file exists and the link prints `../.agents/skills`.
   Open `START.md` and follow your [client guide](../../ai/README.md).

## Link skills in an existing project

Keep the canonical skill files under the project's `.agents/skills`. Preserve
existing client folders and link each selected skill individually. From the
project root, this example links only `day-one-setup`:

```bash
(
  set -euo pipefail
  test -f .agents/skills/day-one-setup/SKILL.md
  mkdir -p .claude/skills
  target=.claude/skills/day-one-setup
  if [[ -e "$target" || -L "$target" ]]; then
    printf 'Preserve existing entry: %s\n' "$target" >&2
    exit 1
  fi
  ln -s ../../.agents/skills/day-one-setup "$target"
)
```

Expected result: `.claude/skills/day-one-setup` points to the canonical project
skill. A normal file, directory or dangling link at the destination is preserved.
Do not move these skills without their referenced guides; a dedicated setup
workspace keeps their relative references valid.

Agent formats differ. Use the Claude definitions for `.claude/agents`, Codex
TOML definitions for `.codex/agents`, and Copilot definitions for `.github/agents`.
Do not symlink one client's agent files into another client's directory.

## Available skills and roles

| Skill | Use it for |
|---|---|
| `day-one-setup` | Inspect, plan and configure selected capabilities |
| `day-one-check` | Audit fresh evidence without repairing |
| `day-one-maintain` | Scoped updates and configuration drift |
| `day-one-recover` | Backup, restore and explicitly selected removal |
| `day-one-omniroute` | Gateway bootstrap and maintenance |
| `day-one-contribute` | Add supported project capabilities and tests |

The planner proposes changes; the operator performs approved work; the verifier
reviews evidence; the maintainer changes the repository. Confirm discovered
roles and permission controls in the client before use.

## Update and remove

Prepare a new workspace from the reviewed version. Compare changed files and
preserve private session notes. Do not overwrite customised definitions blindly.
Remove an old workspace by moving that exact directory to Trash after closing
its sessions and preserving needed notes.

To remove a project symlink, first verify its target with `readlink`, then remove
only that link, without a trailing slash. Do not remove the canonical skills or
an existing client directory as part of unlinking.
