# AI component ownership and compatibility

Day One Mac shares procedures as skills, exposes optional executable tools through
integrations, and supplies opt-in native agent roles. Manual setup remains usable
without any skill, server or permanent checkout.

## Component boundaries

| Category | Responsibility | Source and supporting files |
|---|---|---|
| Skill | Instructions and knowledge selected within a conversation | `templates/skills`, canonical `docs/setup/manual`, AI guidance in `docs/setup/ai` |
| Plugin integration | Executable tools, protocol connections and application actions | `helpers`, `integrations/mcp`, `integrations/shortcuts`, `integrations/warp` |
| Agent | A delegated goal, decisions and evidence across steps | Shared policies in `templates/agents/shared`; generated Codex, Claude and Copilot adapters beside them |

An executable helper belongs to the integration layer without being a native
plugin package. Day One Mac has no Codex or Claude plugin manifest. Its optional
MCP package supplies tools, resources and prompts, not an autonomous agent loop.
MCP prompts carry skill-like instructions; agents consume the server's interface.

`agents/openai.yaml` inside a skill is discovery/UI metadata, not a native agent.
Obsidian templates, Bases, Notion CSVs and knowledge guides are skill assets.
Their directory name `extensions` does not establish a native plugin.

## Public skills and contributor skills

The public catalog contains `day-one-mac`, `day-one-setup`, `day-one-check`,
`day-one-maintain`, `day-one-recover`, `day-one-omniroute`, `day-one-contribute`,
`day-one-shortcuts`, `day-one-second-brain`, `day-one-vscode` and
`day-one-macos-apps`. The main skill bundles the specialist workflows. Prefer
that single entry point; install standalone specialists for selective use.
Generated packages under `skills/` are independent distribution snapshots.
Edit their sources and regenerate them rather than editing snapshots directly.

Repository contributors use these checkout-local skills under `.agents/skills`:

| Skill | Owner of the procedure |
|---|---|
| `day-one-mac-maintenance` | Repository contracts, public sources and recovery boundaries |
| `codebase-design` | Module interfaces and architecture vocabulary |
| `design-taste-frontend` | Visual direction for new or redesigned interfaces |
| `impeccable` | Targeted interface critique, refinement and design procedures |
| `documentation-writer` | Document purpose, structure and reader journey |
| `technical-writing` | Truth, prose and house style |
| `review-and-refactor` | General code review and refactoring |
| `differential-review` | Security-focused change review |
| `systematic-debugging` | Reproduction and root-cause investigation |
| `writing-plans` | Implementation task planning |
| `executing-plans` | Approved plan execution and evidence |
| `verification-before-completion` | Fresh verification before completion claims |

Choose the owner of the requested task; do not load every overlapping skill.
Optional companion references do not authorize installing packages or extending
scope. When a companion is absent, use the skill's local fallback and repository
checks. External skills and host-provided plugins remain separate dependencies.

`day-one-mac-maintenance` maintains this repository. `day-one-maintain` maintains
a Mac environment. `day-one-maintainer` is a delegated repository role. The
[skill installation guide](../../setup/manual/ai/day-one-skills.md#repository-maintenance-versus-environment-maintenance)
owns their installation and packaging distinction.

## Agent policy and activation

`config/catalogs/assistant-agents.json` owns role names, descriptions and the
read-only designation. Each policy under `templates/agents/shared` owns its
instructions. `tools/build-agents.cjs` embeds that policy in generated adapters:

| Role | Scope |
|---|---|
| `day-one-planner` | Inspect and propose a bounded setup plan |
| `day-one-operator` | Execute the user's approved scope |
| `day-one-verifier` | Evaluate evidence without repairs |
| `day-one-maintainer` | Maintain the repository without configuring the live Mac |

The generated adapters are templates. Bundling them inside a skill does not
activate them. Install only the selected native adapter through the client's
supported discovery location. Do not register one on behalf of another client.

Codex planner/verifier adapters disable shell, apps and plugins. They ask the
parent for probes unavailable through their remaining tools. Codex agents still
inherit the parent permission policy; instructions do not establish a separate
read-only sandbox. Direct MCP connections also inherit the parent configuration;
restrict mutation tools in the parent before delegating read-only work. MCP
annotations do not enforce access. Claude planner/verifier adapters allow Read, Glob and Grep
and use plan permission mode. Confirm available tool names in the installed
client before activation.
[Codex agents](https://learn.chatgpt.com/docs/agent-configuration/subagents),
[Claude agents](https://code.claude.com/docs/en/sub-agents).

Impeccable's four nested TOML definitions are contributor-skill assets. They are
not installed in native discovery directories. A Claude skill symlink does not
translate those TOMLs into Claude agents. Use a native adapter when explicitly
installed; otherwise perform the relevant procedure in the current session.

## Shared sources and platform adapters

```text
project/
├── AGENTS.md
├── CLAUDE.md -> AGENTS.md
├── .agents/skills/<name>/SKILL.md
└── .claude/skills/<name> -> ../../.agents/skills/<name>

personal installation/
├── ~/.agents/skills/day-one-mac/
└── ~/.claude/skills/day-one-mac -> ../../.agents/skills/day-one-mac
```

Share whole skill directories so helpers and relative references resolve from
the skill, independent of the working directory. Keep symlink targets stable.
Published packages contain real files and their own required assets. Do not make
them depend on a contributor checkout. Claude Code supports local skill symlinks;
this does not establish compatibility with Claude Desktop or hosted sessions.
[Claude skills](https://code.claude.com/docs/en/skills).

Native agent wrappers cannot share a single file: Codex uses TOML and Claude
uses Markdown with YAML frontmatter. Generate both from the same role policy.
The [project instruction recipe](../../setup/manual/ai/instructions-agents-skills.md)
shows shared policies, native discovery paths and Claude adapter symlinks in a
consuming application repository.

MCP configuration also remains native: Codex uses TOML tables, Claude uses
`mcpServers`, and VS Code uses `servers`. Share the server implementation and
reviewed metadata, not whole client configuration or credential files. Account
authentication, managed policy and permission approvals remain client-specific.

## Integration ownership

The optional MCP server uses `config/mcp/day-one-mac.json` for reviewed guide
sources, client identifiers, timeouts and the default read-only tool list.
Its configuration command prints native entries; it does not merge settings,
start servers or grant permissions. Use one direct or Docker route per server.
The [MCP guide](../../setup/manual/ai/mcp.md) owns client registration and the
[Docker guide](../../setup/manual/ai/mcp-docker.md) owns gateway configuration.

The Day One server exposes preview separately from apply. Startup opt-in and
private backups are required to expose apply; token and drift checks still apply.
Client approval is independent of any confirmation text supplied by a caller.
Containers report their own Linux environment and cannot change Mac preferences.

Angular, Nx, Context7, Azure DevOps, GitHub, Playwright, Postgres and DataGrip MCP
servers are external integrations. Docker is optional connection infrastructure.
Sequential Thinking is a callable tool, not a separately delegated agent.
Documented server examples are not proof of installation or account access.

Shortcut AppleScripts, signed Shortcuts assets, app/Quick Action builders and
Warp workflows own executable actions. The shortcut skill owns procedure;
the archive source owns movement and collision checks. An installed workflow
does not update merely because repository source changes.

VS Code profile JSON and extension catalogs configure external plugins, including
GitLens. OmniRoute is an external routing service; its skill owns setup guidance.
Second Brain inspection is a bounded helper, while vault and Notion assets are
knowledge templates. None of these operations requires an autonomous agent.

Source inventories, package catalogs and manifests describe packaging intent.
Tests, CI, reader generation and build tools validate or distribute their owning
components. Historical plans and compatibility pages remain reference evidence.
Preserve existing guide URLs and recovery records when changing the structure.
