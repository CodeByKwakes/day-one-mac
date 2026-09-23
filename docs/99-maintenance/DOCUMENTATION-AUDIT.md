# Day One Mac documentation audit

**Audit date:** 18 September 2026
**Scope:** every Markdown file below `day-one-mac/` plus the scripts that those
documents ask users to run
**Audience tested:** first-time Terminal user, junior developer, experienced
developer, and developer using a company-managed Mac

## Executive summary

The documentation is structurally sound and safety-conscious. The final
alignment pass resolved the previously listed navigation and working-directory
blockers. The project validator now checks both Markdown files and section
anchors, all shell scripts pass syntax checks, and the required, optional,
advanced, preflight, Warp Drive, finalisation, and Second Brain fixtures pass.

The audit found no instruction that disables Gatekeeper, erases a drive from a
Day One script, places a private SSH key in the repository, or silently replaces
a company-managed application. The `fnm` zsh loader matches the current upstream
form, and the Apple-silicon/Homebrew assumptions remain aligned with the current
official support boundary.

## Follow-up audit — document information architecture

**Review date:** 23 September 2026

The project root previously mixed Markdown files and documentation folders with
runnable project components. The current layout keeps one short `README.md` at
the Day One Mac root. `docs/README.md`, `docs/START-HERE.md`,
`docs/PROCESS-OVERVIEW.md`, and `docs/PROJECT-GUIDE.md` provide the visible
entry points below it. Required work lives under `docs/01-required/`, lookup
material under `docs/20-reference/`, finalisation and removal under
`docs/04-operations/`, and internal audit history under `docs/99-maintenance/`.

Each of those groups now has an index explaining what belongs there. The
previously unindexed `docs/02-optional/` directory also has a Phase-8-gated module map.
Script-generated guide paths, validation targets, Markdown navigation, section
anchors, and raw Warp catalogue paths were updated with the moves. No setup
behavior, state path, portable command name, or phase gate changed.

## Follow-up audit — projectless tasks, worktrees, and AI clients

**Review date:** 23 September 2026

The projectless workflow previously used status folders such as `00_Inbox` and
`01_Active`. Moving a live folder between those locations can invalidate a
Codex task, Claude Code session, VS Code window, or saved terminal path. The
current design therefore gives every task one stable, dated path under
`~/Developer/_Projectless/tasks/<year>/` and records status in `TASK.md`.

The new workspace manager creates the bounded folder, common instructions,
Claude-compatible symlink, and input/working/output boundaries. It refuses the
projectless parent and year containers, never creates a root Git repository,
and leaves detected legacy folders unchanged for a deliberate migration. Warp
workflows call the same manager rather than duplicating folder logic.

Repository-backed work now has a separate documented route: use a sibling Git
worktree under `<repository>.worktrees/`, open only that worktree in VS Code or
an AI client, verify the branch, then remove it with Git after integration. The
VS Code guide now explains Workspace Trust and optional worktree detection.
This removes the former ambiguity between temporary file tasks and branch-based
software work.

## Follow-up audit — complete alignment and application shortcuts

**Review date:** 23 September 2026

The current pass covered every Markdown document below `day-one-mac/`, compared
the required phase descriptions with the phase runner, checked the required,
optional, advanced, Stage 0, application, Warp Drive, and Second Brain
navigation, and reran all executable documentation fixtures.

No blocking mismatch remains in phase order, track numbering, application
ownership, Homebrew detection, optional-module boundaries, or saved-state
terminology. Historical names that remain are explicitly labelled migration
inputs rather than current paths. Gatekeeper-disabling, NVM, and Oh My Zsh text
appears only in “do not use” or historical-comparison sections.

The audit did find one missing usability layer: keyboard shortcuts were spread
between individual guides, and the shared `⌘\\` conflict was not explained.
`app-guides/KEYBOARD-SHORTCUTS.md` now defines intentional global ownership for
Raycast and 1Password, documents the macOS-version-specific 1Password Quick
Access shortcut, resolves the Warp Drive conflict, and provides focused tables
for Raycast, Warp, VS Code, Finder, and macOS. Every required application guide
links to that canonical reference, and validation protects its safety rules.

## Follow-up audit — Homebrew detection and beginner reading path

**Review date:** 23 September 2026

The Phase 2 runner already checked for `/opt/homebrew/bin/brew` before invoking
Homebrew's installer. The review retained that idempotent behaviour and made it
visible: the terminal now says whether it found and reused Homebrew, could not
find it, or found an unsupported Intel/Rosetta location. The last case stops
instead of installing a second package manager beside an unexplained copy.

The manual Phase 2 and Notion instructions now perform the same path-aware
check. `command -v brew` alone was insufficient because a correct existing
installation can be temporarily absent from `PATH` on a new shell.

For navigation, `START-HERE.md` now begins with one six-step safe route and
explains when a reader should open a detailed phase. The validator enforces a
common reader path across all eight required guides: **Outcome**, **How to use
this phase**, numbered actions, a recovery section, and a completion checklist.
This keeps the detailed reference material available without requiring a new
user to read every page before starting.

The six former blockers are now resolved:

1. Phase 1 now points to the correct wizard step.
2. Phase 1, early settings, and Phase 2 navigation now follows the real order.
3. Phase 8 restores the scripts working directory before relative commands.
4. Start Here names the headings the phase files actually use.
5. Required-application links point to the real phase or guide sections.
6. The Second Brain dashboard points to the existing integration-guide anchor.

The new [Notion setup guide](../20-reference/NOTION-SETUP-GUIDE.md) resolves the missing central
manual-versus-script route. The findings below are retained as an audit trail;
the final disposition records which changes were applied and which remaining
ideas are optional editorial improvements.

## Follow-up audit — application ownership and installer choice

After implementing the per-application installer choice, the required phases,
optional modules, app guides, Second Brain guides, central overview, Start Here,
README, and Notion guide were checked again against the executable scripts.

The follow-up found and resolved these alignment issues:

- Required Phases 3 and 4 previously described every missing app as an automatic
  Homebrew installation. They now document the Homebrew, approved external
  installer, and safe-stop choices plus the external live recheck.
- Phase 4 previously installed formulae before displaying application ownership.
  The guide and runner now agree that the complete phase application scan appears
  first.
- Optional database, AI, OmniRoute, Warp Drive, Obsidian, and Codex instructions
  now describe the same choice instead of implying that `--install-missing`
  always means Homebrew.
- The Second Brain `--install-apps` path previously bypassed the common choice.
  Its script and documentation now accept the same explicit policy.
- Phase 8 previously omitted the required Nerd Font from its hard-coded
  application gates. It now reads every required catalogue entry, so future
  required applications cannot be omitted from the final ownership report.
- Non-interactive documentation now requires `--app-install-policy homebrew` or
  `check-only`; `--yes` does not silently assign ownership.

No remaining document tells a guided user that a missing graphical application
will be silently installed. Manual-flow Homebrew commands remain intentionally
visible as explicit commands, with managed-Mac warnings immediately beside
them. Homebrew formulae remain Homebrew-owned because the application ownership
choice applies to catalogue apps, CLIs distributed as casks, and fonts—not the
required command-line formula set.

## Audit method and coverage

- Final pass covered **111 Markdown files**, **63 shell scripts**, the two
  application catalogues, and **63 Warp workflows**.
- Compared the eight required phases with `scripts/setup.sh` and
  `scripts/bootstrap-day-one-mac.sh`.
- Compared Stage 0 documentation with the preflight, backup, and cleanup scripts.
- Checked relative Markdown file targets and the documented navigation order.
- Searched for stale Intel, NVM, Oh My Zsh, disabled-Gatekeeper, fixed-version,
  old-name, and fixed-three-domain assumptions.
- Ran `scripts/validate.sh`, including the Day One Mac, application ownership,
  Stage 0, Warp Drive, and Second Brain regression fixtures.
- Checked current primary documentation for Apple macOS support, Homebrew support
  tiers, fnm zsh initialization, and VS Code settings/approval behavior.

### Coverage by document group

| Group | Files reviewed | Result |
|---|---:|---|
| Root orientation, indexes, and reference documents | 15 | Issues listed below |
| Required phases and early settings | 9 | Issues listed below |
| Required application guides | 4 | Minor alignment issues |
| Optional modules 09–14 | 7 | Navigation and onboarding issues |
| Advanced modules 15–22 | 9 | Mostly aligned; jargon issue |
| Existing-Mac Stage 0 | 7 | Aligned; density improvement recommended |
| Second Brain guides | 10 | Broken anchor and dynamic/fixed terminology issues |
| Second Brain Markdown assets/templates | 28 | No execution blocker; asset role should remain explicit |
| Warp Drive Markdown catalogue | 1 | No blocking issue |

## Resolved blockers — retained as an audit trail

### `01-first-boot-and-decisions.md`

#### Wrong step number for the main wizard

**Location:** line 18
**Former text:** “Read the preparation steps, then use the wizard in Step 1.7.”
**Problem:** Step 1.7 is the chezmoi-protection decision. The wizard is Step 1.8
at line 205. A beginner following the cross-reference lands on the wrong action.

**Suggested replacement:**

> Read the preparation steps, then start the wizard in Step 1.8. Step 1.7
> explains the dotfiles-protection choice that the wizard will ask you to make.

#### Footer skips the early settings checkpoint

**Location:** line 280
**Former text:** “Continue to Phase 2”
**Problem:** The top navigation and current process place the optional macOS
Settings Wizard between Phases 1 and 2. The footer bypasses it.

**Suggested replacement:**

> Continue to Early macOS settings →

### `02-command-line-foundation.md`

#### Back navigation disagrees with the top navigation

**Location:** line 166
**Former text:** “← Phase 1”
**Problem:** The top link correctly points back to Early macOS settings. The
footer returns directly to Phase 1, making the new sequence appear inconsistent.

**Suggested replacement:**

> ← Early macOS settings

### `08-verify-and-reproduce.md`

#### Relative commands can run from the wrong directory

**Locations:** lines 126–127 and 211–219
**Former text:** Step 8.4 changes into `$(chezmoi source-path)`, then the
local-only section later runs `./bootstrap-day-one-mac.sh` without returning to
the Day One scripts directory.
**Problem:** A user executing the page sequentially remains in the chezmoi
source. The relative script does not exist there.

**Suggested replacement:**

```bash
day-one-mac setup --phase 05 --local-dotfiles
day-one-mac setup --phase 08
```

Current implementation note: the standalone installer makes `day-one-mac`
available before Phase 1, and the location-independent form above is now used
throughout user-facing phase guides.

### `START-HERE.md`

#### Promised phase headings do not exist consistently

**Locations:** lines 197–208
**Former text:** users are told to read **Why this phase matters**, **Recommended
automated route**, **What the runner changes**, **Expected result**, and **If the
phase stops**.
**Problem:** Required phases mainly use **Outcome**, **How to use this phase**,
numbered steps, **Troubleshooting**, and a completion checklist. A beginner looks
for headings that are not present.

**Suggested fix:** choose one of these approaches and use it across all eight
phases:

1. Change Start Here to name the headings that already exist; or
2. Add the five promised headings to the phase template and migrate every phase.

The lower-effort, less disruptive fix is option 1:

> Read **Outcome** and **How to use this phase**, complete the numbered steps and
> any manual batch, use **Troubleshooting** if the gate stops, and continue only
> when the completion checklist is true.

### `second-brain/obsidian/DASHBOARD.md`

#### Broken section link

**Location:** line 224
**Former text:** `README.md#choose-a-guide`
**Problem:** The Second Brain README heading is **Choose integration guides after
the layout wizard**, so the generated anchor is different. File-only link
validation does not detect this kind of broken fragment.

**Resolution:** The dashboard now uses the existing **Choose integration guides
after the layout wizard** section. Section-fragment validation now prevents a
similar link from passing the project validator.

## High-priority findings — resolved unless marked as a recommendation

### `README.md`

#### Claims separate guides that are actually sections elsewhere

**Locations:** lines 291–295
**Former text:** “detailed guides for VS Code, Raycast, Warp, 1Password, and the
shared Nerd Font.”
**Problem:** `docs/10-app-guides/` contains dedicated files for VS Code, Raycast, and
Warp. 1Password is covered in Phase 3 and the font is a section in the app-guide
hub. Calling all five “detailed guides” makes users search for files that do not
exist.

**Suggested replacement:**

> Use the required application setup hub for the recommended order. It links to
> dedicated VS Code, Raycast, and Warp guides, Phase 3 for 1Password, and the
> shared Nerd Font check.

#### Maintenance advice is more aggressive than the advanced maintenance guide

**Locations:** lines 449–464
**Former text:** `brew update && brew upgrade` is the first periodic command.
**Problem:** Advanced Module 21 recommends reviewing updates in layers. A blanket
upgrade can change every formula and cask immediately, which is a poor default
for work machines and less experienced users.

**Suggested replacement:**

```bash
brew update
brew outdated --formula
brew outdated --cask
# Upgrade reviewed items, then run brew cleanup after verification.
```

Link directly to Advanced 21 for the full cadence.

#### Compatibility reference should link to the exact Homebrew claim

**Locations:** lines 102–121
**Former text:** Homebrew Tier 1 is asserted, but the link points to the generic
installation page.
**Problem:** The claim is currently correct, but the cited page is not the
clearest evidence and will be harder to re-audit later.

**Suggested fix:** link to `https://docs.brew.sh/Support-Tiers` and retain the
review date.

### `START-HERE.md`

#### Storage prerequisite lacks context

**Location:** line 32
**Former text:** “at least 30 GB of free storage”
**Problem:** It is unclear whether this includes Xcode, container images,
optional databases, project dependencies, and Stage 0 backups. A beginner may
treat it as a guaranteed total.

**Suggested replacement:**

> At least 30 GB free for the required base. Full Xcode, containers, databases,
> AI models, and project dependencies need additional space; keep Stage 0 backup
> capacity on a separate encrypted drive.

### `MACOS-SETTINGS.md`

#### Navigation ends abruptly

**Location:** end of file, after line 146
**Problem:** Unlike required phases, the document has no footer navigation. A
Notion or browser reader who reaches the bottom must scroll to the top to find
Phase 2.

**Suggested addition:**

```markdown
---

[← Phase 1](../01-required/01-first-boot-and-decisions.md) · [Continue to Phase 2 →](../01-required/02-command-line-foundation.md)
```

### `03-security-and-ssh.md`

#### Relative ownership command lacks a local working-directory reminder

**Locations:** lines 41–48
**Problem:** The command begins `./bootstrap-day-one-mac.sh`, but this section
does not repeat `cd .../day-one-mac/scripts`. Users arriving through a search
result may run it from their home directory.

**Resolved:** the public standalone installer now provides the portable
command before Phase 1. User-facing examples use that command; direct scripts
are limited to contributor and recovery contexts.

#### No explicit policy escape hatch for environments that forbid 1Password

**Locations:** lines 5–14 and 329–340
**Problem:** 1Password and its SSH agent are mandatory for the stock gate. That
is a valid project decision, but a company-managed Mac may require another
credential agent. The document explains company-managed application ownership,
not what happens when the security architecture itself is prohibited.

**Suggested addition:**

> If company policy prohibits 1Password or its SSH agent, stop here. The stock
> Day One Mac security gate cannot pass. Record the approved replacement agent
> and create a reviewed project variant instead of skipping the SSH gate or
> installing an unapproved credential tool.

#### Product-specific approval timings need a review date

**Locations:** lines 107–119 and 152–163
**Problem:** Fixed 4/12/24-hour and CLI session behavior can change between
1Password releases. The guide links to the official source but does not say when
the values were last verified.

**Suggested fix:** add a “reviewed on” date and tell users to follow the current
labels in the installed app when they differ.

### `04-core-tools-and-hosting.md`

#### Manual cask block is easy to misuse on a managed Mac

**Follow-up status:** Resolved by the ownership-first phase scan and the
per-application Homebrew/external/safe-stop choice. The manual commands remain
recovery references after the ownership warning.

**Locations:** lines 74–96
**Problem:** The warning is correct, but the next code block installs every cask
in one command. A beginner may copy it before checking which apps Company Portal
already owns.

**Suggested fix:** show the read-only ownership command first, then place each
missing cask behind an individual checkbox. Repeat “install only missing items”
inside the code-block introduction.

#### Track shorthand is inconsistent

**Locations:** lines 94, 110, 125, and 200
**Former text:** “Tracks 2–3”
**Problem:** Elsewhere the guide uses “Tracks 2 and 3.” A range can sound as if
another unnamed track exists.

**Suggested replacement:** consistently use “Tracks 2 and 3.”

### `05-dotfiles-and-shell.md`

#### Manual and automated responsibilities are intertwined

**Locations:** lines 14–23, 70–99, and 190–230
**Problem:** The file explains reference commands, runner-created targets, and
manual changes in the same sequence. A manual reader cannot reproduce the
portable `day-one-mac` dispatcher from this document alone, while an automated
reader may think every snippet must be recreated.

**Suggested fix:** split each relevant step into **Automated route**, **Manual
equivalent**, and **Verification**. State that the dispatcher and setup ownership
metadata are runner features, not prerequisites for using Git, zsh, or the
language toolchains manually.

### `06-language-toolchains.md`

#### `PATH` and `PNPM_HOME` are used before plain-English definition

**Locations:** lines 95–125
**Problem:** The guide explains the ownership model well, but a beginner may not
know that `PATH` is the ordered list of command locations or that `PNPM_HOME` is
where pnpm exposes user-level global commands.

**Suggested addition:** define both terms before the first verification block
and add `PATH` to the glossary.

### `07-vscode-base.md`

#### “Settings file” is ambiguous when profiles are active

**Locations:** lines 49–66
**Problem:** The documented path is the Default profile's user settings. VS Code
profiles have separate settings files. The later optional profile guide explains
this, but a user who already has a profile can inspect the wrong file.

**Suggested addition:**

> This path is the Default profile. If the profile name appears in VS Code's
> title/menu, use **Preferences: Open User Settings (JSON)** in that profile and
> review its separate settings before changing the Default profile.

### `EXPECTED-LAYOUT.md`

#### Safety-report directory shape is stale

**Locations:** lines 101–108
**Former text:** `preflight/<UTC timestamp>/`
**Problem:** The current scripts create human-readable directories named
`Safety Report - YYYY-MM-DD HH-MM-SS`, and Stage 0 can move the authoritative
report beneath the external recovery folder. The tree no longer matches normal
output.

**Suggested fix:** show both the temporary local report and the verified
external location, using the current human-readable name.

#### macOS settings statuses are incomplete

**Location:** line 136
**Former text:** “completed, skipped, or restored”
**Problem:** The script can also record `manual-pending` and `failed`.

**Suggested replacement:**

> `completed`, `manual-pending`, `skipped`, `restored`, or `failed`

### `GLOSSARY.md`

#### Common beginner-facing terms are missing

**Locations:** whole glossary; terms occur elsewhere in the documents
**Missing terms:** `PATH`, environment variable, JSON/JSONC, TOML, TSV, SDK,
symlink, certificate authority (CA), and TCC/privacy database.
**Problem:** These appear in required or advanced instructions but are not
defined in the shared beginner glossary.

**Suggested fix:** add short definitions and link to the glossary on first use
in the owning document.

## Optional, advanced, preflight, and app-guide issues

### `app-guides/README.md`

#### “All three” has an unclear referent

**Locations:** lines 56–65
**Former text:** “you do not need one answer for all three.”
**Problem:** The same page lists 1Password, Raycast, Warp, VS Code, and a font.
The phrase means the three dedicated GUI guides, but that is not explicit.

**Suggested replacement:**

> Choose separately for Raycast, Warp, and VS Code. Phase 3 owns 1Password, and
> the font has no user data to restore.

### `app-guides/RAYCAST.md`, `WARP.md`, and `VSCODE.md`

No blocking inconsistency was found. These guides clearly separate fresh setup,
selective import, sync, export, later changes, and troubleshooting. Recommended
minor improvement: add a one-line **Prerequisites completed** box at the top of
each file naming the exact required phase.

### `optional/09-databases.md`

No blocking inconsistency was found. Keep the current container-first design.
Recommended minor improvement: define “volume” as Docker persistent data on its
first use so it is not confused with the external macOS backup volume.

### `optional/10-ai-agents.md`

No blocking sequence issue was found. Recommended minor improvement: add a
single comparison table for account/billing ownership, local configuration
location, and removal command so a beginner can choose without reading every
client section first.

### `optional/10a-omniroute.md`

#### The 703-line guide lacks a minimum-path summary

**Locations:** lines 38–74 and the complete Step 10A sequence
**Problem:** The three-part explanation is useful, but a first-time user cannot
quickly identify the minimum successful path through container, dashboard,
endpoint key, and one client.

**Suggested addition:** add a six-item **Minimum working route** near the top:

1. Start OrbStack.
2. Start OmniRoute on loopback.
3. Add one provider.
4. Create one endpoint key.
5. Configure one client.
6. Run one read-only request, then add other clients.

### `optional/11-mcp-servers.md`

No command-order blocker was found. Recommended minor improvement: define HTTP
and stdio in the document before the selection table instead of relying only on
the root glossary.

### `optional/12-vscode-profiles.md`

#### Optional navigation stops before Modules 13 and 14

**Locations:** line 1 and line 237
**Problem:** The optional chain links 09 → 10 → 10A → 11 → 12, then returns to
the project home even though Modules 13 and 14 are listed in the same sequence.

**Suggested replacement:** add **Enhanced CLI tools →** to the header and footer;
then link Module 13 to Module 14.

### `optional/13-enhanced-cli-tools.md` and `optional/14-warp-drive.md`

No functional issue was found. Add previous/next navigation so these files are
part of the same optional sequence rather than appearing detached.

### `advanced/15` through `advanced/19`, `advanced/21`, and `advanced/22`

No blocking ordering or contradiction was found. The advanced index correctly
states that the tracker records reviewed completion but does not install the
feature. Rollback boundaries are present.

### `advanced/20-restore-and-migrate.md`

#### Unexplained TCC acronym

**Location:** line 207
**Former text:** “privacy/TCC databases”
**Problem:** TCC is not defined in the file or root glossary.

**Suggested replacement:**

> macOS privacy-permission databases (often called TCC databases)

### `preflight/README.md` and Steps 00–04

No safety or sequence blocker was found. The route chooser, report, encrypted
drive, snapshot, restore test, preview, and cleanup gates align with the current
scripts.

Recommended accessibility improvement: the Stage 0 README's Step 3 description
is dense (lines 67–90). Add a short “What you must do” checklist before the
implementation details, then move socket, nested Git metadata, checksum batching,
and administrator-assisted retry details into a **Technical behavior** subsection.

### `preflight/ENCRYPTED-BACKUP-DRIVE.md`

No blocking issue was found. The destructive Disk Utility action is separated
from the script and clearly warns that formatting erases the selected drive.

### `ROLLBACK.md`

No destructive-safety contradiction was found. The two cleanup boundaries are
clear. Recommended minor improvement: put a two-row **Use broad cleanup / Use
recorded rollback** decision callout immediately after the title, before the
long inventory details.

## Second Brain and generated-asset issues

### `second-brain/obsidian/README.md`

#### Version wording can be mistaken for an installed-app requirement

**Locations:** line 3 and lines 199–206
**Former text:** “Version 2.3.0.0” and “Raycast compatibility baseline”
**Problem:** It is unclear whether 2.3.0.0 is the Second Brain guide release,
the Raycast application version, or both. The document later says not to pin or
downgrade Raycast.

**Suggested replacement:** separate the values:

> Guide release: 2.3.0.0. Tested Raycast baseline: 2.3.x. Use a current supported
> Raycast release; do not downgrade solely to match this guide.

### `second-brain/obsidian/THREE-VAULT-ARCHITECTURE.md`

#### Fixed-three naming conflicts with the dynamic multi-domain model

**Locations:** title and Step 4 at line 169
**Problem:** The manager supports any selected domain count, while this filename
and several headings imply exactly three. The title says “three-domain example,”
but navigation calls it the general three-vault design.

**Suggested fix:** rename the user-facing guide to
`MULTI-VAULT-ARCHITECTURE.md`, describe three vaults as the default example,
and retain the old filename as a short compatibility pointer if external links
may exist.

### `second-brain/obsidian/GUIDE-2-OBSIDIAN-CLAUDE-CODE.md` and
`GUIDE-3-OBSIDIAN-CODEX.md`

**Locations:** Guide 2 line 26; Guide 3 line 24
**Former text:** “All three domains...”
**Problem:** The dynamic manager may create fewer, more, or differently named
domains.

**Suggested replacement:** “All selected domains...” and then label the three
named domains as the default example.

### `second-brain/obsidian/assets/**`

The 28 Markdown assets were reviewed as generated vault content rather than as
setup chapters. No unsafe command or broken setup dependency was found. The
fixed three-domain assets remain explicitly labelled legacy/example content in
the Second Brain README. Keep that label visible; users should normally start
with the dynamic manager-generated assets.

### `warp-drive/Day One Mac/00 Day One Mac Command Catalogue.md`

No blocking issue was found. Track boundaries, placeholders, secrets, and
cleanup-preview rules are stated before the command tables. Recommended minor
Current implementation note: the portable `day-one-mac` command is installed
before Phase 1 and adopted into chezmoi during Phase 5.

## Repeating patterns to fix systematically

### 1. Standardize every procedural document

Use this order consistently:

1. **Outcome**
2. **Prerequisites / before you begin**
3. **Choose manual or automated route**
4. **What changes**
5. **Steps**
6. **Verification**
7. **Troubleshooting / next action**
8. **Completion checklist**
9. **Previous / next navigation**

### 2. Make command working directories explicit

Every relative `./script.sh` block should either include an absolute `cd` first
or state directly above it which directory is required. Do not rely on a command
from an earlier section still controlling the terminal's current directory.

### 3. Use one track vocabulary

Use **Track 1**, **Track 2**, **Track 3**, and “Tracks 2 and 3.” Avoid numeric
ranges such as “2–3” in beginner-facing prose.

### 4. Separate required, optional, and advanced work visually

Retain the existing markers, but add the words in headings and callouts so
meaning never depends on emoji or colour:

- `Required`
- `Optional — can be completed after Phase 8`
- `Advanced optional — requires the base setup`
- `Work/Azure only`

### 5. Define local jargon where it first matters

The glossary is useful but should not be the only definition. Add one short
plain-English sentence before a beginner must act on `PATH`, JSON, TOML, TSV,
symlink, CA, or TCC.

### 6. Fragment/anchor validation — completed

The validator now checks both missing Markdown files and missing `#section`
fragments, so a link such as the dashboard's former `#choose-a-guide` reference
cannot pass validation.

### 7. Date volatile product behavior

Add a “reviewed on” date beside specific macOS menu paths, 1Password approval
durations, AI-client CLI syntax, and app-version claims. Link to the exact
official page that supports the statement.

## Final disposition

Completed in the alignment pass:

1. Resolved all six navigation, anchor, and working-directory blockers.
2. Added local Markdown section-anchor validation.
3. Aligned application ownership, optional-module navigation, phase order,
   track wording, finalisation, and generated portable-command references.
4. Rechecked Apple-silicon macOS 27, Homebrew, fnm, VS Code approval, and
   1Password guidance against the linked primary sources.
5. Added storage context, cautious Homebrew maintenance, profile-aware VS Code
   guidance, missing glossary terms, current Stage 0 paths, and minimum routes
   for OmniRoute and MCP.

Remaining ideas are non-blocking editorial improvements: gradually make every
long optional/advanced guide use identical heading order, shorten the dense
Stage 0 technical explanations without removing them, and consider a future
multi-vault filename alias while retaining the explicit three-vault example
requested by this project. None changes the executable setup result or safety
boundary.

## Documents with no specific issue to fix

The following were reviewed and did not produce a document-specific blocker
beyond the repeating patterns above:

- `APPLICATION-OWNERSHIP.md`
- `PROCESS-OVERVIEW.md`
- `app-guides/RAYCAST.md`
- `app-guides/WARP.md`
- `app-guides/VSCODE.md`
- `optional/09-databases.md`
- `optional/10-ai-agents.md`
- `optional/11-mcp-servers.md`
- `optional/13-enhanced-cli-tools.md`
- `optional/14-warp-drive.md`
- `advanced/README.md`
- Advanced Modules 15–19 and 21–22
- Stage 0 files 00–04 and the encrypted-drive guide
- `second-brain/obsidian/ALTERNATIVE-STACKS.md`
- `second-brain/obsidian/CHECKLIST.md`
- `second-brain/obsidian/DYNAMIC-LAYOUT-MANAGER.md`
- `second-brain/obsidian/GUIDE-1-OBSIDIAN-RAYCAST.md`
- `second-brain/obsidian/OPERATING-SYSTEM.md`
- the Warp Drive command catalogue
- the 28 generated Second Brain Markdown assets and templates

“No specific issue” means the file is usable and aligned with the scripts; it
does not exempt it from the systematic structure, terminology, and volatile-date
recommendations.

## Primary references used for volatile checks

- [Apple — upgrade to macOS 27 Golden Gate](https://support.apple.com/en-us/127455)
- [Homebrew — support tiers](https://docs.brew.sh/Support-Tiers)
- [fnm — official README and zsh setup](https://github.com/Schniz/fnm/blob/master/README.md)
- [VS Code — user and profile settings](https://code.visualstudio.com/docs/configure/settings)
- [VS Code — AI settings reference](https://code.visualstudio.com/docs/agents/reference/ai-settings)
- [VS Code — approvals and permissions](https://code.visualstudio.com/docs/agents/run/approvals)
- [1Password — SSH agent authorization](https://www.1password.dev/ssh/agent/authorization)
- [1Password — CLI integration security](https://www.1password.dev/cli/app-integration-security)
