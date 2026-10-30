# Install Day One Mac skills

Install `day-one-mac` for setup, checks, maintenance, recovery, OmniRoute and
developer shortcuts and repository contribution through one entry point. Its workflows and required
references are bundled. Specialist skills are optional independent installations.
Neither installation requires the Day One Mac runtime or a permanent checkout.

For the main skill plus a read-only local MCP connection, the
[optional native plugin](day-one-plugins.md) is an alternative distribution.
Choose one route for the main skill and avoid duplicate server registrations.

## Prerequisites and source

Use an approved AI client and Node.js 22.20.0 or newer with npm. Check
`node --version` and `npm --version`; follow the [language toolchain guide](../languages.md)
if needed. The commands below use Skills CLI 1.7.4. `npx` downloads the CLI when
it is absent from the npm cache. Review its prompts and selected destinations.

GitHub installation requires a published revision containing `skills/`. A local
commit is available only through the local path until it is pushed. A branch or
release URL selects that published revision; the repository shorthand selects
its default branch. Check the source before installing or updating.

## Install from GitHub

1. Create and enter a dedicated private setup directory:

   ```bash
   SETUP_WORKSPACE="$HOME/Developer/Setup/day-one-$(date +%Y%m%d-%H%M%S)"
   mkdir -p "$(dirname "$SETUP_WORKSPACE")"
   mkdir -m 700 "$SETUP_WORKSPACE"
   cd "$SETUP_WORKSPACE"
   ```

   Expected result: a new directory. Stop if the destination already exists.
   Project installation writes here, so avoid starting in an unrelated repository.

2. List the published skills:

   ```bash
   npx skills@1.7.4 add CodeByKwakes/day-one-mac --list
   ```

   Expected result: `day-one-mac` appears. If it is absent, the default branch
   does not contain the package; use a published revision URL or the local route.

3. Install the main skill for the clients you use:

   ```bash
   npx skills@1.7.4 add CodeByKwakes/day-one-mac \
     --skill day-one-mac \
     --agent codex github-copilot claude-code
   ```

   Expected result: `.agents/skills/day-one-mac/SKILL.md` and bundled references
   exist. Review the displayed installation destinations. Remove client names
   you do not use. Choose the shared/symlink method when prompted.

For a published branch, tag or commit, use the full GitHub tree URL pointing to
its `skills/day-one-mac` directory as the source. Replace `PUBLISHED_REF` with
an actual published revision; it is not a literal branch name:

```bash
npx skills@1.7.4 add \
  https://github.com/CodeByKwakes/day-one-mac/tree/PUBLISHED_REF/skills/day-one-mac \
  --skill day-one-mac --agent codex github-copilot claude-code
```

## Install from a local checkout or source archive

1. Open Terminal in the reviewed Day One Mac source directory and record its path:

   ```bash
   DAY_ONE_SOURCE="$(pwd -P)"
   test -f "$DAY_ONE_SOURCE/skills/day-one-mac/SKILL.md"
   ```

   Expected result: the test succeeds without output. Stop if the package is absent.

2. Create and enter a new setup directory using step 1 of the GitHub procedure.

   Expected result: the destination differs from the source checkout.

3. Install the prepared package:

   ```bash
   npx skills@1.7.4 add "$DAY_ONE_SOURCE/skills" \
     --skill day-one-mac \
     --agent codex github-copilot claude-code
   ```

   Expected result: the installed skill contains its own references. The normal
   shared/symlink method copies the package into `.agents/skills` and links client
   locations to that copy. It does not depend on retaining the source checkout.
   Avoid a development source-link mode when you need an independent installation.

Selecting only Claude Code makes CLI 1.7.4 copy directly into `.claude/skills`.
Use `.claude/skills/day-one-mac` instead of `.agents/skills/day-one-mac` in the
verification and role-source examples for that selection. Selecting Codex,
Copilot and Claude together supports the shared copy with a Claude symlink.

To install without the Skills CLI, copy the reviewed `skills/day-one-mac` folder
into a new `.agents/skills/day-one-mac` directory in your setup workspace. Preserve
all files and subdirectories. For Claude, follow the linking procedure below.

## Verify and start

1. List installed project skills and check the entry point:

   ```bash
   npx skills@1.7.4 list
   test -f .agents/skills/day-one-mac/SKILL.md
   test -f .agents/skills/day-one-mac/references/workflows/day-one-check.md
   ```

   Expected result: the main skill is listed and both file checks succeed.
   No specialist installation is needed for its bundled workflows.

2. Open this directory in the chosen client and request a read-only check:

   ```text
   Use day-one-mac to inspect my development environment. Start with the check
   workflow and report evidence, missing prerequisites and suggested next steps.
   Do not install, update or remove anything.
   ```

   Expected result: the client reads the installed main skill and its check
   workflow, then reports observations. Skill installation does not sign in to
   a provider, install an AI client or grant additional execution permissions.

3. For setup, request a plan before execution:

   ```text
   Use day-one-mac to plan my selected development setup. Preserve working tools.
   Offer direct provider access, existing OmniRoute, local OmniRoute or gateway
   setup later. Include commands, affected paths, verification and recovery.
   ```

   Expected result: a plan for the selected capabilities. Approve the intended
   changes in the client. Keep private progress notes outside the installed skill
   directory, for example under `session/` in this workspace.

## Project and global installations

Project installation is recommended for a dedicated setup workspace. Codex and
Copilot use its `.agents/skills` directory. Claude uses a link from `.claude/skills`
when installed for that client. Verify the destinations displayed by the CLI.

Add `--global` to the install command only when you want the skill available
across projects. The CLI manages each selected client's user-level locations.
Use the matching scope for listing, updating and removal. Global installation
still does not install applications or change provider credentials.

## Optional specialist skills

| Skill | Purpose | Included in the main skill |
|---|---|---|
| `day-one-setup` | Plan and configure selected developer tools | Yes |
| `day-one-check` | Audit fresh evidence without repairing | Yes |
| `day-one-maintain` | Perform scoped updates and review drift | Yes |
| `day-one-recover` | Back up, restore or remove selected owned components | Yes |
| `day-one-omniroute` | Bootstrap and maintain a selected gateway | Yes |
| `day-one-contribute` | Change a separately selected source repository | Yes |
| `day-one-second-brain` | Set up knowledge systems, link selected code repositories and inspect connections | Yes |
| `day-one-shortcuts` | Inspect, build and maintain selected developer shortcuts and standalone apps | Yes |
| `day-one-vscode` | Inspect and maintain profiles, extensions, User Settings, shortcuts and recovery | Yes |
| `day-one-macos-apps` | Review app ownership, preferences, permissions, updates and scoped removal | Yes |

Install a specialist by replacing `--skill day-one-mac` with its exact name.
Multiple names can follow `--skill`. Avoid `--all`: this repository also contains
contributor skills that are separate from these distributable packages.

### Repository maintenance versus environment maintenance

Choose the skill by the thing being maintained. Repository contributor
instructions and a user's development-environment workflows have separate homes.

| Skill | Purpose | Source and distribution |
|---|---|---|
| `day-one-mac-maintenance` | Maintain this checkout's guides, packages and helpers | Repository-local `.agents/skills/day-one-mac-maintenance/SKILL.md`; excluded from public packages |
| `day-one-maintain` | Review drift and update selected developer tools or installed skills | `templates/skills/day-one-maintain/SKILL.md`; generated into `skills/day-one-maintain` and bundled in the main skill |
| `day-one-contribute` | Guide repository changes from a separately selected source checkout | `templates/skills/day-one-contribute/SKILL.md`; generated into `skills/day-one-contribute` and bundled in the main skill |

The repository-local skill supplements this checkout's `AGENTS.md` and
`CONTRIBUTING.md`. It is not a missing public template or a dependency to install
on a user's Mac. Keep public workflow instructions in `templates/skills/` and
regenerate their `skills/` packages; keep checkout-specific contributor guidance
in `.agents/skills/`. Installing the main skill includes both public workflows
without copying the repository-local contributor skill.

### Install and use the shortcuts specialist

For shortcuts, use the same GitHub/local installation steps with
`--skill day-one-shortcuts`. Project/global scope and Claude links work the same
way. Ask: "Use day-one-shortcuts to preview Git Clone and Open in Warp apps in a
new review directory. Preserve my installed shortcuts." Follow the
[builder reference](../../../shared/tools/shortcut-apps.md) after approving the
preview. Updating or removing a skill does not update or remove generated apps;
their lifecycle belongs to the [manual shortcut guide](../apps/macos-shortcuts.md).

## Editor and application specialists

Use `day-one-vscode` for profile work and `day-one-macos-apps` for application or
System Settings work. Both are bundled into `day-one-mac`; choose independent
installation only when you prefer their narrower entry points.

1. In your setup workspace, select one source:

   ```bash
   npx skills@1.7.4 add "$DAY_ONE_SOURCE/skills" \
     --skill day-one-vscode day-one-macos-apps \
     --agent codex github-copilot claude-code
   ```

   For a published revision containing these packages, use:

   ```bash
   npx skills@1.7.4 add CodeByKwakes/day-one-mac \
     --skill day-one-vscode day-one-macos-apps \
     --agent codex github-copilot claude-code
   ```

   Expected result: only the selected specialists are installed for the chosen
   clients. Define `DAY_ONE_SOURCE` using [Install from a local checkout](#install-from-a-local-checkout-or-source-archive)
   before the local command. Add `--global` only for user-level availability.

2. Verify the installed entry points:

   ```bash
   test -f .agents/skills/day-one-vscode/SKILL.md
   test -f .agents/skills/day-one-macos-apps/SKILL.md
   ```

   Expected result: both commands succeed for the project installation above.
   Use the CLI-reported destination for global or Claude-only installations.

3. Start with a bounded request:

   ```text
   Use day-one-vscode to review my Full Stack profile. Compare extensions and
   formatting settings with the bundled recipe. Propose changes without applying them.
   ```

   ```text
   Use day-one-macos-apps to review Warp and its login setting. Preserve its
   installation owner and current preferences. Propose changes without applying them.
   ```

   Expected result: observations and a scoped proposal. Approve the selected
   changes when ready. Skill installation alone does not modify profiles or apps.

Follow [Update and remove](#update-and-remove) with the exact specialist name
and installation scope. Removing a skill leaves your configured applications
and their private recovery backups intact.

## Optional agent roles

The main and setup packages include four role definitions per client under
`assets/agents/`. Skills work without activating these roles. Agent formats differ;
use the native files for each client, preserving existing project configuration.

1. Choose one client and locate its templates from the workspace root:

   ```bash
   ROLE_SOURCE=".agents/skills/day-one-mac/assets/agents/codex"
   ROLE_TARGET=".codex/agents"
   ```

   Expected result: the source contains four TOML files. For Claude, use the
   `claude` source and `.claude/agents`; for Copilot, use `copilot` and `.github/agents`.

2. Copy the selected files only after checking for collisions:

   ```bash
   (
     set -euo pipefail
     test -d "$ROLE_SOURCE"
     for source in "$ROLE_SOURCE"/*; do
       target="$ROLE_TARGET/$(basename "$source")"
       if [[ -e "$target" || -L "$target" ]]; then
         printf 'Preserve existing role: %s\n' "$target" >&2
         exit 1
       fi
     done
     mkdir -p "$ROLE_TARGET"
     cp "$ROLE_SOURCE"/* "$ROLE_TARGET/"
   )
   ```

   Expected result: four project roles. Refresh the client and verify discovery
   before relying on them. Roles inherit the client's account and permission
   controls. They do not turn a read-only session into an execution session.

## Link skills in an existing project

The CLI handles client links during installation. For a manual copy, keep the
canonical files under `.agents/skills` and link only the selected Claude skill:

```bash
(
  set -euo pipefail
  test -f .agents/skills/day-one-mac/SKILL.md
  mkdir -p .claude/skills
  target=.claude/skills/day-one-mac
  if [[ -e "$target" || -L "$target" ]]; then
    printf 'Preserve existing entry: %s\n' "$target" >&2
    exit 1
  fi
  ln -s ../../.agents/skills/day-one-mac "$target"
)
```

Expected result: the link points to the single canonical copy. Preserve existing
files, directories and dangling links. Never symlink one client's agent format
into another client's agent directory.

## Second Brain specialist

Install `day-one-second-brain` when you only want knowledge-system setup and
selected repository connections. The `day-one-mac` umbrella already includes it.
Use the private setup directory described above, not the skill's source directory.

For a published revision containing the package:

```bash
npx skills@1.7.4 add CodeByKwakes/day-one-mac \
  --skill day-one-second-brain --agent codex github-copilot claude-code
```

For a local checkout, record `DAY_ONE_SOURCE` using the earlier local-source
steps, then run this from the chosen installation workspace:

```bash
npx skills@1.7.4 add "$DAY_ONE_SOURCE/skills" \
  --skill day-one-second-brain --agent codex github-copilot claude-code
```

Add `--global` only for deliberate user-wide availability. A skill installed in a
setup folder is available there; it does not automatically appear in a separate
vault workspace. Choose a workspace or user scope that fits how you start sessions.
For a Claude-only install, verify `.claude/skills` rather than `.agents/skills`.

Verify the project installation:

```bash
npx skills@1.7.4 list
node .agents/skills/day-one-second-brain/references/project/helpers/second-brain/inspect.cjs --help
```

Expected: the skill is listed and the helper prints usage without inspecting
notes. Start with a plan request:

```text
Use day-one-second-brain to inspect my selected knowledge system and propose
setup changes. Preserve existing notes and settings. Do not modify anything yet.
```

Choose actual vaults and repositories privately during that session. Follow
[manual setup](../second-brain/README.md), [connections](../second-brain/repositories.md)
and the [checker reference](../../../shared/tools/second-brain-connections.md).
Installing a skill does not register a repository or grant a client access to it.

To update just this specialist from its reviewed source, repeat its matching
`add` command with the same clients and scope. Inspect the proposed replacement;
keep your private connections and notes outside the installed package.
Remove only the selected project skill with:

```bash
npx skills@1.7.4 remove day-one-second-brain --agent codex github-copilot claude-code
```

Use `--global` for a global removal. This removes the installed skill for the
selected clients; it does not delete vaults, project notes, connection records or
backups. End sessions with old context and review separately configured access
when disconnecting a repository. Umbrella users update or remove `day-one-mac`
instead; no specialist installation is required for that bundled workflow.

## Update and remove

Before an update, preserve customisations outside the installed package and
review the source changes. For project installations, run from that workspace:

```bash
npx skills@1.7.4 update day-one-mac --project
```

Expected result: only `day-one-mac` is updated from its recorded source, leaving
unrelated skills unchanged. Use `--global` instead of `--project` for a user-level
installation. In CLI 1.7.4, `check` is an alias for `update`, so it is not a
read-only preview. Inspect the source diff before running the scoped update.

For a local-path source, regenerate packages in the checkout when maintaining
them, then repeat the local `add` command. Do not assume remote update checks can
fetch a local-only source.

Remove just the selected skill with:

```bash
npx skills@1.7.4 remove day-one-mac
```

Expected result: the selected skill and its client links are removed after
confirmation. Add `--global` for a user-level installation. Preserve `session/`
notes and unrelated skills. Agent role files copied separately remain separate;
remove only those exact files after reviewing any local changes.

Use [assistant operation](../../ai/operation.md) for planning, approval and
private progress notes. Optional role templates are bundled; activate them
separately through the steps above. There is no workspace export command.
For CLI behaviour and client destinations, see the
[Skills CLI reference](https://github.com/vercel-labs/skills/blob/main/docs/commands.md)
and [supported clients](https://github.com/vercel-labs/skills/blob/main/docs/agents.md).
