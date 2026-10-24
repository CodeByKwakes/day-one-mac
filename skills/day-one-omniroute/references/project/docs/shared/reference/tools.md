# Reviewed utility reference

The optional `day-one-mac` command performs individually selected operations.
It does not run whole-machine setup. The manual route needs none of these tools;
AI-assisted execution may use them when the approved plan calls for them.

## Prerequisites and lifecycle

Install a version that includes the command using the [runtime guide](../tools/runtime.md).
Run `day-one-mac --help` and the selected command's `--help` before use. Actual
prerequisites belong to each operation: platform, executable, selected input,
file ownership and application access. Historical phase markers are not gates.

Preview first. Read-only checks may still contact an explicitly selected local
service. Apply operations preserve their existing locks, ownership records and
recovery data. A generated artifact is not proof that a client imported it.

## Command families

| Command | Purpose | Guide |
|---|---|---|
| `assistant` | Export/check a private guide, skills and agents workspace | [Assistant operation](../../setup/ai/operation.md) |
| `tool --list` | List reviewed capability IDs and their prerequisites | Table below |
| `tool --module ID` | Plan/apply/check/resume one selected capability | Table below |
| `vscode-profile` | Generate, install extensions or review settings replacement | [Profiles](../tools/vscode-profiles.md) |
| `folders` | Selected folder layout and optional ghq | [Folders](../../setup/manual/development/folders.md) |
| `applications`, `inventory` | Inspect installation ownership and application availability | [Ownership](application-ownership.md) |
| `shell-status` | Inspect PATH, completions and shell integrations | [Shell](../../setup/manual/shell/README.md) |
| `safety-report` | Private existing-Mac inspection report | [Preparation](../../setup/manual/backup-and-restore.md) |
| `readiness`, `audit`, `modules` | Inspect policy, environment and saved utility evidence | [Readiness](workstation-readiness.md) |
| `rollback` | Preview recovery of recorded owned changes | [Recovery](../tools/rollback.md) |
| `shortcuts`, `raycast`, `workspace` | Reviewed optional integrations | [Shortcuts](../tools/shortcuts.md), [Raycast](../tools/raycast.md), [workspaces](../tools/ai-workspaces.md) |
| `second-brain` | Obsidian layouts or a local Notion plan | [Second Brain](../../setup/manual/second-brain/README.md) |
| `docs`, `verify`, `runtime-status`, `update`, `rollback-runtime`, `uninstall-runtime` | Guides and runtime lifecycle | [Runtime](../tools/runtime.md) |

`optional` and `advanced` are compatibility aliases for explicit `tool`
operations. Bare aliases never open a setup wizard. `databases`, `cli-tools`
and `macos-settings` retain their standalone help and selection interfaces.

## Reviewed capabilities

IDs are stable compatibility identifiers, not an installation order.

| ID | Operation | Actual prerequisite or boundary | Guide |
|---|---|---|---|
| 09 | Disposable databases | Selected local engine and synthetic-data consent | [Databases](../tools/09-databases.md) |
| 10 | AI client payloads | Selected clients and installation owner | [Clients](../tools/10-ai-agents.md) |
| 10A | OmniRoute container | Local engine/context and reviewed image digest | [Gateway](../tools/10a-omniroute.md) |
| 11 | MCP snippets | Valid metadata; activation remains manual | [MCP](../tools/11-mcp-servers.md) |
| 13 | CLI formulae | Existing Homebrew and selected packages | [CLI tools](../tools/13-enhanced-cli-tools.md) |
| 14 | Warp export | Bundled assets; import remains manual | [Warp](../tools/14-warp-drive.md) |
| 15 | Dotfile proposals | Explicit paths and ownership selection | [Dotfiles](../tools/15-full-dotfiles-and-bootstrap.md) |
| 16 | Software inventory | Selected metadata and installation owner | [Software](../tools/16-brewfile-apps-and-editor.md) |
| 17 | Shell helper proposals | Selected helpers; activation remains manual | [Helpers](../tools/17-shell-and-package-automation.md) |
| 18 | Identity/worktree review | Explicit repositories and expected metadata | [Identity](../tools/18-hosting-identities-azure-and-worktrees.md) |
| 19 | Scalar macOS preferences | Supported keys and recoverable originals | [Preferences](../tools/19-macos-gui-and-local-https.md) |
| 20 | Restore staging | Checksummed source and a new staging destination | [Staging](../tools/20-restore-and-migrate.md) |
| 21 | Audit evidence | Recorded scope; unknown remains unverified | [Audit](../tools/21-audit-maintenance-and-rebuild.md) |
| 22 | Skill/MCP inventory | Explicit sources; never executes inventoried skills | [Governance](../tools/22-ai-skills-and-mcp-operations.md) |

Module 12 remains retired. Use `vscode-profile` for profiles.

## Verification example

```bash
day-one-mac tool --module 14 --plan
day-one-mac tool --module 14 --apply
day-one-mac tool --module 14 --check
```

Expected result: a preview, a confirmed private export, then a file check.
This does not import anything into Warp or prove a workflow runs there.

For component updates/removal, use [lifecycle guidance](../../setup/manual/lifecycle.md).
Existing installations should read [migration](../migration/from-scripted-setup.md).
