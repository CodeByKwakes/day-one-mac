# Second Brain skill and repository connections implementation plan

> For agentic workers: use the executing-plans skill after proposal approval.
> Recommended execution is inline implementation followed by an independent
> review. This proposal does not authorize live vault changes or publication.

**Goal:** Provide a self-contained Second Brain skill that configures a knowledge
system and connects selected code repositories to project notes with reviewed AI access.

**Architecture:** Canonical manual guides own setup recipes. A specialist skill
selects those recipes and is also bundled into `day-one-mac`. A private connection
file records selected checkouts; an optional read-only helper validates those selections.

**Tech stack:** Markdown, Obsidian core features, optional Notion, JSON, Node.js
22.20+, Git, the existing Skills CLI packaging and repository validation tools.

**Spec:** The user's request to review Second Brain setup and propose a skill,
plus their clarification: link selected code repositories to project notes with
scoped AI access. The design below is proposed, pending approval.

## Scope and defaults

Recommend Obsidian for local Markdown notes and file-based repository references.
Preserve Notion as a supported guided alternative for an existing cloud workspace.
Do not migrate an existing knowledge system merely to follow the default.

Start with one vault and the domains the user selects. Separate work and personal
vaults when their account, sync or access policies differ. Record application
ownership, permitted AI clients and backup expectations before installing anything.

Repository connections mean project references and approved reading of selected
files. Vault Git synchronization, automatic indexing, background monitoring,
remote cloning, commits, pushes and source-code changes are outside this proposal.
Existing backup guidance remains available separately.

The initial implementation supports Codex, GitHub Copilot in VS Code and Claude
Code. Local repository reading requires no MCP server. Optional Notion access
uses an available approved connector, or manual steps when no connector exists.

## Review findings

Reviewed the Second Brain entry points, Obsidian setup/integration/layout guides,
Notion structure and AI/recovery guidance, relevant vault assets and launchers,
skill catalogue, package builder, inventories and acceptance tests.

Evidence refers to repository commit `2dd8d02`. Current gates pass, but they do
not exercise complete live Second Brain workflows or legacy launcher behavior.

| Finding | Evidence | Proposed correction |
|---|---|---|
| No dedicated Second Brain skill exists | `config/catalogs/assistant-skills.json`; `templates/skills/day-one-mac/SKILL.md` | Add the specialist and bundle its workflow into the umbrella skill |
| Repository connections stop at a URL and path | `docs/setup/manual/second-brain/README.md`, final section; vault `99 Templates/Project.md`; Notion `03-databases-and-properties.md`, Projects | Add selected paths, connection lifecycle, source evidence and client-specific access guidance |
| The basic capture example uses `software-development`; the other Obsidian guides and templates use `development` | `obsidian/README.md:52`; `obsidian/raycast.md:81`; vault `90 System/Knowledge System.md` | Establish one property contract and preserve existing values until a migration is approved |
| Current dashboard guidance promises a retired manager and report | `obsidian/dashboard.md:81` and `:180`; `docs/shared/tools/second-brain.md` | Remove the unsupported promise and link current manual or skill checks |
| Raycast verification mixes a Store extension, Quicklink and old generated commands | `obsidian/raycast.md:170-188` | Verify the installed extension's actual capture target and use the created Quicklink consistently |
| Some steps assume assets the minimal setup never creates | `obsidian/README.md:34-42`; `obsidian/raycast.md:111-125`; `obsidian/claude.md:221` | Separate required starter files from optional templates, Bases and source folders; show their creation before use |
| Claude and Codex templates duplicate policy text | `extensions/second-brain/obsidian/assets/vault/AGENTS.md` and `CLAUDE.md`; three-vault equivalents | Maintain shared rules once and create reviewed client links or thin adapters during setup |
| Legacy launcher assets still depend on old configuration | `assets/manager/**` expects `layout.tsv`; single/three-vault launchers source shell configuration | Trace callers, retire orphaned scripts and keep direct client startup recipes; preserve user-owned installed files and recovery state |
| Package contents do not include the complete vault starter | The catalogue includes only `assets/vault/99 Templates`; installed umbrella currently contains those eight templates | Bundle the selected starter assets explicitly, without a checkout dependency |
| The Second Brain section lacks a Copilot guide | `docs/setup/manual/second-brain/obsidian/` | Add VS Code guidance and verify instruction/skill discovery in the selected workspace |

The canonical layout guide already explains that separate folders do not enforce
access permissions. Carry that distinction into all client guides and templates.
The current Codex guide's security link also resolves to the separate Codex
Security product; point permission guidance to its actual owner.

## Skill behavior

| Request | Skill actions | Result |
|---|---|---|
| Set up or adopt | Inspect the selected location, propose a minimal layout, preserve existing notes and settings, configure approved integrations | A usable vault or Notion workspace with capture, search and recovery checks |
| Connect a repository | Register the selected checkout and permitted files, create or update its project note after review | A project reference without copying the source tree |
| Review repository knowledge | Inspect approved files, cite paths and the observed revision, draft decisions or learning notes | A proposal in the vault's AI Review area, or an explicitly selected Notion page |
| Check | Inspect selected structure, properties, links, connection paths and backup evidence | A read-only findings report; untested recovery remains unverified |
| Maintain or extend | Propose new domains, templates, dashboard changes or refreshed repository summaries | A bounded diff with preserved user content |
| Disconnect or remove | Remove an approved connection record or skill integration, preserving notes and code | A narrower configuration; no repository or vault deletion |
| Recover | Locate the user's selected backup and restore a harmless sample separately | Evidence of recovery without replacing the live vault |

Each task reports inspected scope, changed paths, skipped material and unresolved
manual steps. Setup and repair use a concrete plan before changes. Existing task
approvals remain valid unless the scope changes.

## Repository connection design

Keep a private JSON connection file in a user-selected setup workspace, outside
installed skills and public source control. It is passive data, never sourced as
shell code. Cloud-vault notes contain only policy-approved project references;
machine paths remain in the private local file.

Proposed version-one record:

```json
{
  "schema": 1,
  "vault": "<selected absolute vault path>",
  "repositories": [
    {
      "id": "sample-api",
      "checkout": "<selected absolute checkout path>",
      "projectNote": "10 Software Development/Projects/Sample API.md",
      "readPaths": ["README.md", "docs/architecture"],
      "aiAccess": "selected-files"
    }
  ]
}
```

The placeholders illustrate fields and are not a runnable connection. Accept
`link-only` and `selected-files` for `aiAccess`; default new connections to
`link-only`. IDs remain stable when a checkout moves. `projectNote` is a relative
vault note path; Notion projects use a page reference instead through a documented
alternative field, `projectPage`, mutually exclusive with `projectNote`.
Require the top-level `vault` path when a connection uses `projectNote`; omit it
for a Notion-only connection file. This gives the checker an explicit overlap boundary.

Use exact relative files or directory prefixes in `readPaths`, with no shell
expansion or glob expressions. Start with documentation. Add particular code,
Prisma schemas, Nx configuration or tests only when the task requires them.
Reject path traversal, vault/code overlap, symlink escapes and duplicate IDs.
Treat worktrees as selected checkouts, including their `.git` pointer files.

The read-only helper validates the connection and lists eligible tracked regular
files before the AI reads their bodies. It excludes `.env` files, credentials,
Git internals, dependency/build trees, binary files, submodules and unapproved
paths. A denylist is not a secret detector; the user still reviews selected files.
Do not evaluate repository configuration or run project scripts during inspection.

A project note records its connection ID, purpose, relevant paths, source revision,
review date and next action. Generated notes identify whether evidence came from
a commit or local changes. A dirty checkout must never be cited as pristine HEAD.
Approved summaries link back to source evidence; stale summaries are flagged on
request rather than refreshed by a background process.

Disconnecting removes future workflow selection. It cannot erase previous AI
conversations or previously generated notes. Removing the skill likewise leaves
the vault and repositories intact.

## Client access and instruction ownership

Repository inspection and vault writing are separate steps. Read the approved
repository scope first, then review the proposed note before writing it. Check
actual client permissions; a connection record and an instruction file do not
enforce operating-system access restrictions.

- Codex: start inspection with read-only permissions. Do not use `--add-dir`
  as a read-only connection; that flag grants additional write access.
- Claude Code: use plan mode for inspection. Additional directories follow the
  active permission mode, and file rules do not cover arbitrary subprocesses.
- Copilot: document the selected VS Code workspace, supplied context and tool
  approvals. A multi-root workspace does not make its repositories read-only.
- When a hard boundary cannot be demonstrated, use reviewed extracts in an
  isolated workspace or stop before reading restricted material.

Create one shared `AGENTS.md` policy after reviewing any existing instructions.
For Claude, offer a relative `CLAUDE.md -> AGENTS.md` link without overwriting a
real file. Verify Copilot's instruction discovery or use a minimal client adapter.
Keep installed skill packages as regular files; client links are setup outcomes.

Define the difference between reading permission metadata and reading note bodies.
Do not claim that `ai_allowed: false` prevents filesystem access. Existing explicit
approval for a named note should not trigger repeated approval questions.

Vendor checks on 2026-10-25: installed Codex help and the official
[command reference](https://learn.chatgpt.com/docs/developer-commands) describe
`--add-dir` as write access. The official
[approval guide](https://learn.chatgpt.com/docs/agent-approvals-security),
[Claude permissions](https://code.claude.com/docs/en/permissions) and
[VS Code security guide](https://code.visualstudio.com/docs/agents/run/security)
explain the relevant controls. Recheck installed versions during implementation.
No live AI account or vault connection has been tested for this proposal.

## File ownership and proposed changes

```text
templates/skills/day-one-second-brain/SKILL.md       new specialist instructions
templates/skills/day-one-mac/SKILL.md               add the bundled workflow route
docs/setup/manual/second-brain/README.md            entry point and choices
docs/setup/manual/second-brain/repositories.md      canonical connection procedure
docs/setup/manual/second-brain/obsidian/
  note-contract.md                                property and layout conventions
  copilot.md                                      VS Code integration
  backup.md                                       shared Obsidian recovery procedure
  existing guides                                 repair inconsistencies and link owners
helpers/second-brain/inspect.cjs                    optional read-only connection check
config/second-brain/repositories.example.json       public placeholder data only
extensions/second-brain/obsidian/assets/             reviewed templates and starter assets
config/catalogs/assistant-skills.json               specialist and scoped asset metadata
config/{skill,document}-sources.txt                 reviewed public inventories
tools/build-skills.cjs                             optional per-skill assets
skills/day-one-second-brain/                        generated standalone package
skills/day-one-mac/                                 generated umbrella workflow and references
tests/integration/test-second-brain.cjs             connection and read-only guarantees
```

Update the README, skill lifecycle guide, shared tool reference and applicable
packaging tests. Preserve compatibility pages and anchors. Inspect every legacy
asset's callers before removal; Git history preserves removed source assets.
Do not remove installed launchers, private layout files or recovery records.

The builder should combine existing shared assets with optional per-skill assets.
The umbrella receives assets required by its bundled workflows. This prevents
adding every vault starter to unrelated skills solely because they share a catalogue.
Keep current package completeness guarantees while making this narrow extension.

## Global constraints

- Preserve the AI-assisted and manual routes, with no runtime or setup runner.
- Keep manual recipes runnable without project helpers or a source checkout.
- Package only reviewed regular public files; keep private outputs outside skills.
- Preserve existing note contents, application owners, backups and user instructions.
- Do not scan all of `~/Developer`, clone repositories or discover private remotes.
- Use selected local checkouts for GitHub, Azure DevOps and other Git hosts alike.
- Do not install services, schedule jobs, add credentials or enable synchronization.
- Changes to the real Mac, accounts or vault require their own concrete task scope.

## Review focus

- Existing vault customizations must survive setup and repeated runs.
- Spaces, Unicode, moved checkouts and Git worktrees must resolve predictably.
- Symlinks, traversal and forbidden files must not expand selected read scope.
- Client permission descriptions must match actual controls and preserve limitations.
- Standalone skill updates/removal must preserve private notes and connections.

## Implementation tasks

### Task 1: Repair the canonical guides and starter contract

Files: the Second Brain manual guides and vault assets listed above; add
`note-contract.md`, `backup.md` and `repositories.md`.

Consumes the reviewed findings and chosen repository-connection scope. Produces
one property vocabulary, a runnable minimal layout and a manual connection recipe.

- [ ] Repair each current-guide inconsistency and preserve public anchors.
- [ ] Consolidate duplicated setup, backup and instruction rules into their owners.
- [ ] Make dashboard/template requirements explicit for one or multiple vaults.
- [ ] Trace legacy launcher callers and remove only orphaned runtime-dependent assets.
- [ ] Verify a fresh minimal fixture and an existing customized fixture. Confirm
  capture, source-note paths and selected dashboards agree without a manager.
- [ ] Run Markdown lint and document/link validation; review the resulting diff.

### Task 2: Add selected repository checks and client guidance

Files: `helpers/second-brain/inspect.cjs`, the example JSON, `repositories.md`,
`obsidian/copilot.md`, existing Codex/Claude guides and
`tests/integration/test-second-brain.cjs`.

Interface: `node inspect.cjs --connections FILE [--repo ID]`. It writes a JSON
report to stdout with schema, selected IDs, checkout state, eligible relative
paths and findings. Exit 0 means valid selections; 1 means invalid or unavailable
selections; 2 means invalid arguments. It creates no files or network requests.

- [ ] Add failing fixtures for normal repositories, worktrees, missing paths,
  duplicate IDs, dirty files, symlink escapes, path traversal and forbidden files.
- [ ] Implement validation using argument arrays for Git commands and bounded file
  inspection. Avoid shell evaluation, project scripts and remote operations.
- [ ] Compare fixture contents before and after checks, including Git metadata.
  Set `GIT_OPTIONAL_LOCKS=0` for inspection commands that could refresh the index.
- [ ] Document the exact local connection, change, refresh and disconnect steps.
- [ ] Document client-specific inspection and draft-review workflows. Verify
  version-dependent options before providing configuration examples.
- [ ] Run the new fixtures and confirm invalid selections do not reveal contents.

### Task 3: Package the skill and integrate the umbrella

Files: the new specialist, umbrella source, skill catalogue, both inventories,
`tools/build-skills.cjs`, `tests/integration/test-skills-package.cjs`, README,
`docs/setup/manual/ai/day-one-skills.md` and generated `skills/` packages.

Consumes canonical guides, reviewed assets and the inspection helper. Produces
an independently installable specialist and the same workflow inside `day-one-mac`.

- [ ] Define concise routing for setup, connect, check, maintain and recover.
- [ ] Add optional per-skill assets and umbrella dependency inclusion. Test asset
  containment and complete packages without broadening public-source rules.
- [ ] Generate packages with `node tools/build-skills.cjs` and validate them.
- [ ] Document GitHub/local install, global/project scope, update and removal.
- [ ] Test the specialist and umbrella after their source checkout disappears.
- [ ] Verify selected-skill removal preserves unrelated skills and private records.

### Task 4: Verify the complete workflow and publish review evidence

- [ ] Run `tools/validate.sh --all` and `actionlint`.
- [ ] Run the pinned Skills CLI acceptance in `CONTRIBUTING.md`, including the new
  skill for all three clients and both project/global scopes.
- [ ] Rebuild the website/offline export and check the new guides and links.
- [ ] Exercise setup/adoption, selected-repo summaries, denied reads, moved
  checkouts, recovery and disconnect using disposable fixtures.
- [ ] Obtain an independent final review of permissions, lifecycle and packaging.
- [ ] Report automated evidence separately from live UI/account checks. Present
  the diff and installation steps; commit or publish only when requested.

## Planned installation and use

After the new skill is implemented and published, the specialist command will be:

```bash
npx skills@1.7.4 add CodeByKwakes/day-one-mac \
  --skill day-one-second-brain --agent codex github-copilot claude-code
```

For local testing before publication, use the reviewed checkout's `skills`
directory as the source. Updating the `day-one-mac` umbrella will also provide
this workflow, so users will not need both installations.

Example requests:

- "Use day-one-second-brain to inspect my existing vault and propose setup changes."
- "Connect this checkout to its project note; inspect only README.md and docs/architecture."
- "Draft a project summary from the approved files and cite the observed revision."
- "Check my selected repository connections without changing any files."
- "Disconnect this project while keeping its notes and source code."

## Approval boundary

This turn committed the earlier approved changes. Only this proposal and its
maintainer index entry are new. Implementation, skill installation, private
repository registration and live vault changes have not been performed.

Approve the proposed repository work to begin implementation. Recommended order:
repair the guide contract, add connection checks, package the skill, then validate.
A later real setup session selects actual vaults, repositories and account permissions.
