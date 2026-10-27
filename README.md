# Day One Mac

Set up and maintain a development environment on an Apple-silicon Mac through
AI-assisted or manual instructions. Choose the tools you need, preserve their
installation owners and verify each capability before relying on it.

## Choose your route

Open the [developer handbook](https://codebykwakes.github.io/day-one-mac/) in a
browser, or read the guides below on GitHub. If the website has not been published
yet, these repository links work independently. The handbook includes search,
printing and a complete offline download; readers need no installation.

- [AI-assisted setup](docs/setup/ai/README.md): prepare one client, choose direct
  provider access or OmniRoute, then review and execute a bounded setup plan.
- [Manual setup](docs/setup/manual/README.md): follow the same tool recipes
  yourself, without installing or calling Day One Mac scripts.

Begin with [Start here](docs/START-HERE.md). Shared prerequisites, decisions,
verification and troubleshooting live in the [shared library](docs/shared/README.md).
The [documentation index](docs/README.md) lists the topic guides.

## Install the AI skill

Use the single `day-one-mac` skill for setup, checking, maintenance, recovery,
Second Brain knowledge workflows, OmniRoute, developer shortcuts and repository contribution. It includes these
workflows and their references. Specialist skills can also be installed independently.

You need Node.js 22.20.0 or newer, npm and an approved AI client. Create and enter
a dedicated setup folder before installing; project scope is the default.

```bash
SETUP_WORKSPACE="$HOME/Developer/Setup/day-one-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$(dirname "$SETUP_WORKSPACE")"
mkdir -m 700 "$SETUP_WORKSPACE"
cd "$SETUP_WORKSPACE"
```

### From GitHub

The selected published revision must contain `skills/`. The default-branch
command becomes available after these packages are published there. List first:

```bash
npx skills@1.7.4 add CodeByKwakes/day-one-mac --list
npx skills@1.7.4 add CodeByKwakes/day-one-mac \
  --skill day-one-mac --agent codex github-copilot claude-code
```

Remove client names you do not use and review the installer prompts. A full
GitHub tree URL can select a published branch, tag or commit. Local commits
are not available from GitHub until pushed.

For a Claude-only selection, the CLI copies to `.claude/skills`; use that path
in the verification example instead of `.agents/skills`.

### From a local checkout

Record the source path while in the reviewed checkout, then enter the setup
folder created above:

```bash
DAY_ONE_SOURCE="/absolute/path/to/day-one-mac"
cd "$SETUP_WORKSPACE"
npx skills@1.7.4 add "$DAY_ONE_SOURCE/skills" \
  --skill day-one-mac --agent codex github-copilot claude-code
```

Replace the source placeholder with the actual checkout or extracted archive.
The prepared skill packages are included; end users do not need to build them.
Choose the shared/symlink installation method for one canonical installed copy.

### Second Brain setup and repository notes

Use the umbrella skill above or install the `day-one-second-brain` specialist.
It supports existing or new Obsidian vaults, guided Notion setup and selected code
repositories linked to project notes. It does not synchronize vaults through Git.

For a published revision containing this skill:

```bash
npx skills@1.7.4 add CodeByKwakes/day-one-mac \
  --skill day-one-second-brain --agent codex github-copilot claude-code
```

For local installation, record `DAY_ONE_SOURCE` from the reviewed checkout as
shown above, enter the private setup folder, then run:

```bash
npx skills@1.7.4 add "$DAY_ONE_SOURCE/skills" \
  --skill day-one-second-brain --agent codex github-copilot claude-code
```

Start with: "Use day-one-second-brain to inspect my selected knowledge system
and propose setup changes. Do not modify anything yet." Choose actual repository
paths only in that private session. Follow [manual Second Brain setup](docs/setup/manual/second-brain/README.md),
[repository connections](docs/setup/manual/second-brain/repositories.md) and the
[skill lifecycle guide](docs/setup/manual/ai/day-one-skills.md#second-brain-specialist)
for verification, scope, updates and removal. Updating `day-one-mac` includes the
same workflow, so you do not need both installations.

### Verify and use it

```bash
npx skills@1.7.4 list
test -f .agents/skills/day-one-mac/SKILL.md
```

Open the setup folder in your client and ask:

```text
Use day-one-mac to check my development environment. Report what works,
what needs attention and the proposed next steps. Do not make changes.
```

See [skill installation and lifecycle](docs/setup/manual/ai/day-one-skills.md)
for global scope, specialist selection, optional agent roles, updates, removal
and examples for setup. Client sign-in and execution permissions remain separate.

## VS Code and macOS application skills

The main `day-one-mac` skill includes two focused workflows:

| Skill | Use it for |
|---|---|
| `day-one-vscode` | Profile audits, extension selection, User Settings, shortcuts, backup and recovery |
| `day-one-macos-apps` | App installation ownership, preferences, permissions, updates and scoped removal |

For independent installation, run one command in your private setup workspace:

```bash
npx skills@1.7.4 add "$DAY_ONE_SOURCE/skills" \
  --skill day-one-vscode day-one-macos-apps \
  --agent codex github-copilot claude-code
```

Define `DAY_ONE_SOURCE` using the local installation steps above. Once the
selected GitHub revision contains the packages, you can use:

```bash
npx skills@1.7.4 add CodeByKwakes/day-one-mac \
  --skill day-one-vscode day-one-macos-apps \
  --agent codex github-copilot claude-code
```

Add `--global` only when you want user-level availability. Installing these
skills does not change applications or profiles. Follow the
[specialist examples and verification](docs/setup/manual/ai/day-one-skills.md#editor-and-application-specialists)
before requesting changes. One installation of the main skill already includes
both workflows.

## Helpers, offline reading and migration

For only developer shortcuts, select `day-one-shortcuts` using either source:

```bash
npx skills@1.7.4 add CodeByKwakes/day-one-mac \
  --skill day-one-shortcuts --agent codex github-copilot claude-code
npx skills@1.7.4 add "$DAY_ONE_SOURCE/skills" \
  --skill day-one-shortcuts --agent codex github-copilot claude-code
```

Run one command in your setup workspace. The GitHub source must contain the
published package; the local source works before publication. Add `--global`
only for a user-level skill installation. The main skill already includes this
workflow, so a second installation is unnecessary.

Ask the skill to inspect existing shortcuts or preview the five
[developer apps](docs/setup/manual/apps/macos-shortcuts.md#build-standalone-apps-manually):
Git Clone, VS Code, Warp, a VS Code profile chooser and a shared development
workspace. Skill installation does not install apps. The optional
[builder](docs/shared/tools/shortcut-apps.md) creates review copies; manual setup
uses Script Editor. Built apps contain their code and require no permanent checkout.

Skills include reviewed [helpers](docs/shared/reference/tools.md) for VS Code
profiles, shortcut apps and read-only version checks. They need no global Day One Mac command.
Manual setup remains independent of helpers. See [reading options](docs/shared/reading-and-export.md)
for website bookmarks, offline downloads and contributor builds. The installed
AI skill includes its own guides and does not need the website to operate.

If the old manager is installed, use the
[legacy removal guide](docs/shared/migration/remove-legacy-manager.md). Preserve
working developer tools, settings and recovery backups.

## Repository layout

| Location | Responsibility |
|---|---|
| `docs/setup/ai/` | Client preparation and assistant operation |
| `docs/setup/manual/` | Canonical tool setup and lifecycle recipes |
| `docs/shared/` | Prerequisites, references, reviewed tools and migration |
| `skills/` | Generated, self-contained skill packages for installation |
| `templates/skills/`, `templates/agents/` | Maintained skill instructions and client roles |
| `config/` | Reviewed source inventories, tool catalogues and VS Code profile data |
| `helpers/` | Bounded helpers also bundled into portable skills |
| `integrations/`, `extensions/` | Optional application assets and Second Brain |
| `tools/`, `tests/`, `maintainers/` | Contributor tooling, regression tests and project history |

See [Contributing](CONTRIBUTING.md) to add a capability. Run `pnpm run skills:build`
after changing skill sources or their linked guides; `pnpm run skills:check`
verifies generated packages. Contributor skills under `.agents/skills/` are
separate from the distributable setup skills.

<a id="start-here"></a>
<a id="install-without-keeping-a-repository"></a>

<a id="optional-tools-and-assistant-workspace"></a>
