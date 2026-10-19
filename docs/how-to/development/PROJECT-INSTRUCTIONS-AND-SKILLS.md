# Project instructions, agents and skills

This focused reference was extracted from the advanced VS Code guide.
Follow the [base editor setup](../apps/VSCODE.md) and [profile guide](../apps/VSCODE-PROFILES.md) first.
[Advanced development reference](VSCODE-TYPESCRIPT.md).

## 9. Share project instructions, skills, and agents

### Canonical project layout

```text
project/
├── AGENTS.md
├── CLAUDE.md -> AGENTS.md
├── .agents/
│   ├── skills/<skill-name>/SKILL.md
│   ├── roles/fullstack-reviewer.md
│   └── compat/claude/fullstack-reviewer.md
├── .github/agents/fullstack-reviewer.agent.md
├── .codex/agents/fullstack-reviewer.toml
└── .claude/
    ├── skills/<skill-name> -> ../../.agents/skills/<skill-name>
    └── agents/fullstack-reviewer.md
        -> ../../.agents/compat/claude/fullstack-reviewer.md
```

Codex and current Copilot use `.agents/skills` directly. Claude gets links, not
copies. Do not add an unnecessary `.github/skills` alias. A discovery UI may
expose the same physical skill through multiple supported paths. Personal
skills under your home directory remain separate from these project skills.
[VS Code skill discovery](https://code.visualstudio.com/docs/agent-customization/agent-skills),
[Codex discovery](https://learn.chatgpt.com/docs/build-skills).

### Shared instructions

Create or merge `AGENTS.md` in the application repository, not in this setup
repository merely because you are reading the guide:

```markdown
# Project conventions

- Read package.json and the lockfile before choosing commands.
- Use the installed framework versions and repository package manager.
- Inspect Nx projects and targets before running tasks.
- Preserve Nx library boundaries, tags, and existing architecture.
- Follow the existing Angular state and form patterns.
- Preserve NestJS validation and authorization boundaries.
- Do not edit generated Prisma client files.
- Review migration SQL before applying it.
- Use project skills when their descriptions match the task.
- Run relevant checks and report actual results and limitations.
```

The link script below exposes the same file as `CLAUDE.md`. Configured Copilot
reads `AGENTS.md` directly, so a second copilot-instructions copy is unnecessary
for this local setup. Cloud workflows have their own supported instruction
locations and do not inherit untracked local files.

### One review policy, three small agent wrappers

Create `.agents/roles/fullstack-reviewer.md`:

```markdown
# Full Stack Review Policy

Review the requested changes without modifying files.
Check TypeScript correctness, Angular template/state behaviour,
NestJS validation and authorization, Nx boundaries, Prisma transactions,
migration compatibility, and relevant PostgreSQL performance concerns.
Report actionable findings with file locations and consequences.
Distinguish confirmed defects from questions.
Do not claim checks ran without execution evidence.
```

Create `.github/agents/fullstack-reviewer.agent.md` for Copilot:

```markdown
---
name: Full Stack Reviewer
description: Review Angular, NestJS, Nx, TypeScript, and Prisma changes.
tools: ['read', 'search']
---

Before reviewing, read `.agents/roles/fullstack-reviewer.md`
from the repository root and follow it. Do not modify files.
```

Confirm read/search tool sets with the selected harness's tool picker.
Create `.codex/agents/fullstack-reviewer.toml` for Codex:

```toml
name = "fullstack_reviewer"
description = "Review Angular, NestJS, Nx, TypeScript, and Prisma changes."
developer_instructions = """
Before reviewing, read .agents/roles/fullstack-reviewer.md
from the repository root and follow it. Do not modify files.
"""
```

Current Codex supports project TOML agents and inherits the parent's permissions.
Instructions do not create a separate read-only sandbox. If needed, merge this
into personal `~/.codex/config.toml`, preserving an existing agents table:

```toml
[agents]
enabled = true
max_concurrent_threads_per_session = 2
```

Create `.agents/compat/claude/fullstack-reviewer.md`:

```markdown
---
name: fullstack-reviewer
description: Review Angular, NestJS, Nx, TypeScript, and Prisma changes.
tools: Read, Grep, Glob
---

Before reviewing, read `.agents/roles/fullstack-reviewer.md`
from the repository root and follow it. Do not modify files.
```

Agent metadata is format-specific, but the review policy is maintained once.
Do not rename a Codex TOML file to Markdown and expect conversion.
[Copilot agents](https://code.visualstudio.com/docs/agent-customization/custom-agents),
[Codex agents](https://learn.chatgpt.com/docs/agent-configuration/subagents),
[Claude agents](https://code.claude.com/docs/en/sub-agents).

### Link project skills and the Claude adapter manually

Run after creating instructions/adapters and installing skills. This Bash 3.2
compatible recipe preserves existing files and differing links:

```bash
bash <<'BASH'
set -eu
task_repo_root=$(git rev-parse --show-toplevel)
cd "$task_repo_root"
mkdir -p .claude/skills .claude/agents

link_once() {
  task_link_target=$1
  task_link_path=$2
  if [ -L "$task_link_path" ]; then
    if [ "$(readlink "$task_link_path")" != "$task_link_target" ]; then
      printf 'Existing link points elsewhere: %s\n' "$task_link_path"
    fi
  elif [ -e "$task_link_path" ]; then
    printf 'Existing file/directory preserved: %s\n' "$task_link_path"
  else
    ln -s "$task_link_target" "$task_link_path"
    printf 'Linked: %s\n' "$task_link_path"
  fi
}

for task_skill_dir in .agents/skills/*; do
  [ -f "$task_skill_dir/SKILL.md" ] || continue
  task_skill_name=${task_skill_dir##*/}
  link_once "../../.agents/skills/$task_skill_name" \
    ".claude/skills/$task_skill_name"
done
if [ -f AGENTS.md ]; then
  link_once "AGENTS.md" "CLAUDE.md"
fi
if [ -f .agents/compat/claude/fullstack-reviewer.md ]; then
  link_once "../../.agents/compat/claude/fullstack-reviewer.md" \
    ".claude/agents/fullstack-reviewer.md"
fi
BASH
```

Verify a link with `readlink` and open the target through the link. Restart
Claude after creating its first agents directory and confirm reviewer discovery.
Claude explicitly documents skill-folder symlinks; agent-file symlinks rely on
filesystem behaviour and should be checked in your installed version. If an
agent link is not discovered, keep the shared policy and place the tiny adapter
directly in `.claude/agents` instead.
[Claude skill symlinks](https://code.claude.com/docs/en/skills).

To remove a known link without removing its target, use `unlink` with no trailing
slash. Never recursively delete a target directory merely to replace a link.

### Keep local project AI files out of Git

Editor User Settings need no exclusion. If project AI files should also remain
personal, open the local exclude file:

```bash
code "$(git rev-parse --git-path info/exclude)"
```

Add only the untracked personal paths you own, for example:

```gitignore
/.agents/
/.claude/skills/
/.claude/agents/
/.codex/agents/
/.github/agents/fullstack-reviewer.agent.md
/AGENTS.md
/CLAUDE.md
/skills-lock.json
/.mcp.json
/.codex/config.toml
```

Existing tracked files remain tracked. Do not hide team-owned files or overwrite
their instructions. Excluded local files do not follow a new clone/worktree;
reinstall/relink them there. Alternatively, share project AI files in Git while
keeping editor preferences personal. See [AI operations](../modules/advanced/22-ai-skills-and-mcp-operations.md).

## 10. Choose and install project skills

Install a small task-relevant set, not a whole catalogue. Run the commands from
the application root. `npx skills add` is the command; there is no `npx add
skills` equivalent. Use `--agent codex github-copilot`, omit `--global` and
`--copy`, and select **Symlink** if prompted. Claude links are added by section 9.
[Skills CLI](https://github.com/vercel-labs/skills).

Sources and names were checked in the source repositories and Skills CLI.
Approximate install counts are a dated adoption signal, not a quality guarantee.
Official ownership and version fit take priority.

### Core skills

| Skill | Source / adoption at check | Why and when |
|---|---|---|
| `angular-developer` | Official Angular; about 42K | Components, signals, DI, routing, HTTP, forms, accessibility, tests; use the installed Angular version |
| `nx-workspace` | Official Nx; about 66K | Explore project graphs, targets, and conventions before monorepo changes |
| `nx-run-tasks` | Official Nx; about 3.7K | Select and run the right build/lint/test/affected targets |
| `nx-generate` | Official Nx; about 3.6K | Scaffold apps/libraries/code using repository conventions |
| `nestjs-best-practices` | Kadajett community; about 29.5K, repository about 289 stars | API architecture, DI, validation, security, testing, performance; not a NestJS-team skill |

Sources: [Angular](https://github.com/angular/skills),
[Nx workspace](https://github.com/nrwl/nx-ai-agents-config/blob/main/skills/nx-workspace/SKILL.md),
[Nx tasks](https://github.com/nrwl/nx-ai-agents-config/blob/main/skills/nx-run-tasks/SKILL.md),
[Nx generation](https://github.com/nrwl/nx-ai-agents-config/blob/main/skills/nx-generate/SKILL.md),
[NestJS](https://github.com/Kadajett/agent-nestjs-skills).

```bash
npx skills@latest add angular/skills \
  --skill angular-developer --agent codex github-copilot
npx skills@latest add nrwl/nx-ai-agents-config \
  --skill nx-workspace nx-run-tasks nx-generate --agent codex github-copilot
npx skills@latest add Kadajett/agent-nestjs-skills \
  --skill nestjs-best-practices --agent codex github-copilot
```

The older Analog Angular skill pack is deprecated; do not install it alongside
the official pack. Use Nx generation rather than Angular CLI new-app guidance
when adding another application to an existing Nx workspace.
[Analog deprecation](https://github.com/analogjs/angular-skills).

### Database skills: check Prisma's major version

| Skill | Source / adoption | Why and when |
|---|---|---|
| `prisma-client-api` | Official Prisma; about 359K | Prisma v7 query API, relations, transactions, and raw queries |
| `prisma-cli` | Official Prisma; about 357K | Prisma v7 generation, migrations, and introspection commands |
| `prisma-database-setup` | Official Prisma; about 358K | Initial database/provider configuration; optional for an established app |
| `supabase-postgres-best-practices` | Supabase-maintained; about 443K | PostgreSQL indexing, schema/query performance, and connection behaviour; apply Supabase-specific advice only when relevant |

For a compatible **Prisma 7** project:

```bash
npx skills@latest add prisma/skills \
  --skill prisma-client-api prisma-cli prisma-database-setup \
  --agent codex github-copilot
```

For PostgreSQL:

```bash
npx skills@latest add supabase/agent-skills \
  --skill supabase-postgres-best-practices --agent codex github-copilot
```

The Prisma registry explicitly distinguishes v7 skills from current
package-shipped skills. Do not apply v7 guidance unconditionally to Prisma 8.
`prisma-postgres` targets the Prisma Postgres service, not every PostgreSQL
database. [Prisma skills](https://www.prisma.io/docs/ai/tools/skills),
[PostgreSQL skill](https://github.com/supabase/agent-skills/blob/main/skills/supabase-postgres-best-practices/SKILL.md).

For a Prisma version supporting native synchronization, inspect the project's
Prisma configuration. Its `skills: { agents: ['agents'] }` option restricts
output to `.agents/skills`; `npx prisma skills sync` uses installed-package skills.
Without that option it can write multiple harness copies. This is a project
Prisma configuration change, not a VS Code setting; do not add it merely to
format a schema. [Native synchronization](https://docs.prisma.io/docs/cli/skills).

### Containers, investigation, and verification

| Skill | Source / adoption | Why and when |
|---|---|---|
| `docker-build-strategies` | Official Docker; newer pack, about 764 | Dockerfiles, multi-stage builds, caching, size, and non-root execution |
| `docker-compose-patterns` | Official Docker | Service wiring, health checks, volumes, networks, development overrides |
| `systematic-debugging` | Superpowers; about 291K | Reproduce a failure and find its cause before changing code |
| `verification-before-completion` | Superpowers | Require actual checks before reporting a fix/refactor complete |

```bash
npx skills@latest add docker/skills \
  --skill docker-build-strategies docker-compose-patterns \
  --agent codex github-copilot
npx skills@latest add obra/superpowers \
  --skill systematic-debugging verification-before-completion \
  --agent codex github-copilot
```

Sources: [Docker skills](https://github.com/docker/skills),
[Compose](https://github.com/docker/skills/blob/main/skills/docker-compose-patterns/SKILL.md),
[debugging](https://www.skills.sh/obra/superpowers/systematic-debugging),
[verification](https://github.com/obra/superpowers/blob/main/skills/verification-before-completion/SKILL.md).
Check existing global skills first; skip project duplicates of the same workflow
unless you deliberately need a different version.

### Optional specialized skills

| Skill | Why and when |
|---|---|
| `typescript-advanced-types` | Complex generic/library APIs; community skill, about 87K; skip for routine CRUD |
| `playwright-cli` | Angular user-flow reproduction and browser evidence; official Microsoft tool, needs its executable/browser setup |
| `pipelines-build-summary` | Azure DevOps build/log investigation; Microsoft sample requiring an authenticated MCP server |
| `boards-work-item-summary` | Azure DevOps acceptance criteria and linked context; same MCP dependency |

```bash
npx skills@latest add wshobson/agents \
  --skill typescript-advanced-types --agent codex github-copilot
npx skills@latest add microsoft/playwright-cli \
  --skill playwright-cli --agent codex github-copilot
npx skills@latest add microsoft/azure-devops-skills \
  --skill pipelines-build-summary boards-work-item-summary \
  --agent codex github-copilot
```

Sources: [TypeScript skill](https://www.skills.sh/wshobson/agents/typescript-advanced-types),
[Playwright CLI](https://github.com/microsoft/playwright-cli),
[Azure DevOps samples](https://github.com/microsoft/azure-devops-skills).
For CLI browser workflows, install Microsoft's executable separately with
`npm install -g @playwright/cli@latest`. Do not additionally install its skill
copies if the canonical skill above is already present. Choose this workflow
or Playwright MCP based on the task; both are not required for the same test.

No special Prettier skill is needed: its executable configuration is the source
of formatting rules. Generic monorepo skills overlap the official Nx set.
