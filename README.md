# Day One Mac

Set up and maintain a development environment on an Apple-silicon Mac. Follow
manual instructions yourself, or use an AI assistant to inspect the Mac and
propose selected changes. Keep working tools with their existing installation
owners and verify each capability before relying on it.

## Start here

1. Read [prerequisites](docs/shared/prerequisites.md) and test an independent
   backup when the Mac contains important data.
2. Record selected tools and owners in the private
   [decision worksheet](docs/shared/decisions.md).
3. Choose one setup route in [Start here](docs/START-HERE.md):

   | Route | Who performs changes | Begin |
   |---|---|---|
   | Manual | You run each command and complete application steps | [Manual sequence](docs/setup/manual/README.md) |
   | AI-assisted | You review instructions or approve a client's scoped work | [Prepare the assistant](docs/setup/ai/README.md) |

Expected: a selected route and recovery plan. Neither route needs a global Day
One Mac command, background manager or permanent source checkout. Managed
software and permissions remain subject to the device owner's policy.

## Choose AI delivery only if needed

| Delivery | Choose it when | Complete procedure |
|---|---|---|
| Main skill | You want the assistant's instructions and bundled guides | [Skill installation](docs/setup/manual/ai/day-one-skills.md) |
| Native plugin | You also want Day One Mac's read-only local MCP tools in Codex or Claude Code | [Plugin installation and lifecycle](docs/setup/manual/ai/day-one-plugins.md) |

The main `day-one-mac` skill includes setup, checking, maintenance, recovery,
VS Code, application, shortcut, Second Brain and gateway workflows. You do not
need separate specialist installations for these capabilities. Install a
specialist only when you deliberately want its narrower scope. Choose one
active delivery method for the main skill in each client.

### Install the main skill from GitHub

Use Node.js 22.20.0 or newer, npm and an approved AI client. The selected
published revision must contain `skills/`; local commits are unavailable until
pushed. In Terminal, create and enter a new private setup folder:

```bash
SETUP_WORKSPACE="$HOME/Developer/Setup/day-one-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$(dirname "$SETUP_WORKSPACE")"
mkdir -m 700 "$SETUP_WORKSPACE" && cd "$SETUP_WORKSPACE"
```

Expected: a new setup workspace, not an unrelated project. List the packages:

```bash
npx skills@1.7.4 add CodeByKwakes/day-one-mac --list
```

Expected: `day-one-mac` appears. If it does not, use a reviewed published revision
or the [local-source procedure](docs/setup/manual/ai/day-one-skills.md#install-from-a-local-checkout-or-source-archive).
Install only for your selected clients; remove unused client names:

```bash
npx skills@1.7.4 add CodeByKwakes/day-one-mac \
  --skill day-one-mac --agent codex github-copilot claude-code
```

Expected: the installation summary shows the chosen workspace and clients.
Review prompts and choose the shared/symlink method. Follow the
[verification steps](docs/setup/manual/ai/day-one-skills.md#verify-and-start),
then ask: "Use day-one-mac to check my selected development tools. Report what
works and what needs attention. Do not make changes."

The same guide owns global scope, source archives, specialist selection,
Claude links, updates and removal. Client sign-in and execution permissions
are separate from skill installation.

## Find a task or get help

Use the [documentation index](docs/README.md) for supported capabilities and the
[troubleshooting index](docs/shared/troubleshooting.md) for a failing step.
The [shared library](docs/shared/README.md) owns prerequisites, terminology,
verification and recovery boundaries. [Client acceptance](docs/shared/reference/client-acceptance.md)
distinguishes documented behaviour, fixtures and live checks.

Read the [browser handbook](https://codebykwakes.github.io/day-one-mac/) or use
repository links if it is unavailable. The [reading guide](docs/shared/reading-and-export.md)
covers offline downloads, search and printing. Reading needs no installation.
Installed skills have their own guide snapshot; changing the website does not
update an installed skill or application.

Existing users can [retire the legacy manager](docs/shared/migration/remove-legacy-manager.md)
while preserving current tools, plugin artifacts and recovery evidence.

## Repository ownership

| Location | Responsibility |
|---|---|
| `docs/setup/manual/` | Canonical setup and lifecycle recipes |
| `docs/setup/ai/`, `docs/shared/` | Assistant operation and shared references |
| `templates/skills/`, `templates/agents/` | Maintained skill instructions and role policies |
| `skills/` | Generated, independently installable packages |
| `config/` | Reviewed inventories, catalogues and profile data |
| `helpers/`, `integrations/`, `extensions/` | Bounded tools and optional application assets |
| `tools/`, `tests/`, `maintainers/` | Contributor tooling, checks and historical records |

Follow [Contributing](CONTRIBUTING.md) to change the project. Edit sources, then
regenerate packages; do not edit generated skills directly. Repository
maintenance instructions are separate from the public setup skill. See
[component ownership](docs/shared/explanation/ai-components.md),
[security reporting](SECURITY.md) and the [MIT licence](LICENSE).

## Published section links

Earlier bookmarks remain below. Installation variants are maintained in the
[skill lifecycle guide](docs/setup/manual/ai/day-one-skills.md); task links are
in the documentation index above.

<a id="choose-your-route"></a>
<a id="install-the-ai-skill"></a>
<a id="from-github"></a>
<a id="from-a-local-checkout"></a>
<a id="second-brain-setup-and-repository-notes"></a>
<a id="verify-and-use-it"></a>
<a id="vs-code-and-macos-application-skills"></a>
<a id="helpers-offline-reading-and-migration"></a>
<a id="repository-layout"></a>
<a id="install-without-keeping-a-repository"></a>
<a id="optional-tools-and-assistant-workspace"></a>
