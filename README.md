# Day One Mac

Set up and maintain a development environment on an Apple-silicon Mac through
AI-assisted or manual instructions. Choose the tools you need, preserve their
installation owners and verify each capability before relying on it.

## Choose your route

- [AI-assisted setup](docs/setup/ai/README.md): prepare one client, choose direct
  provider access or OmniRoute, then review and execute a bounded setup plan.
- [Manual setup](docs/setup/manual/README.md): follow the same tool recipes
  yourself, without installing or calling Day One Mac scripts.

Begin with [Start here](docs/START-HERE.md). Shared prerequisites, decisions,
verification and troubleshooting live in the [shared library](docs/shared/README.md).
The [documentation index](docs/README.md) lists the topic guides.

## Optional tools and assistant workspace

The optional `day-one-mac` command provides reviewed operations for inventory,
configuration proposals, VS Code profiles and recovery. It does not orchestrate
whole-machine setup. See the [utility reference](docs/shared/reference/tools.md)
and [runtime installation](docs/shared/tools/runtime.md).

An [assistant workspace](docs/setup/ai/operation.md) bundles the guides, shared
skills and role configurations for Codex, Claude Code and GitHub Copilot.
It works independently of a permanent source checkout. Exporting it does not
install a client or change global client settings.

Existing installations should read [migration](docs/shared/migration/from-scripted-setup.md)
before updating. Historical ownership and recovery records are preserved.

## Repository layout

| Location | Responsibility |
|---|---|
| `docs/setup/ai/` | Client preparation and assistant operation |
| `docs/setup/manual/` | Canonical tool setup and lifecycle recipes |
| `docs/shared/` | Prerequisites, references, reviewed tools and migration |
| `templates/skills/`, `templates/agents/` | Distributable assistant skills and client roles |
| `config/` | Capability catalogues, policies and VS Code profile data |
| `src/`, `scripts/` | Optional utilities, packaging and compatibility notices |
| `integrations/`, `extensions/` | Optional application assets and Second Brain |
| `tools/`, `tests/`, `maintainers/` | Contributor tooling, regression tests and project history |

See [Contributing](CONTRIBUTING.md) to add a capability. Repository contributor
skills under `.agents/skills/` are separate from the distributable setup skills.

<a id="start-here"></a>
<a id="install-without-keeping-a-repository"></a>
