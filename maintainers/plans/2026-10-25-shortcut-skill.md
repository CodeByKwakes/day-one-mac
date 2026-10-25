# Developer shortcut skill implementation plan

> Use executing-plans for inline implementation and one fresh final review.

**Goal:** deliver the approved five developer shortcuts, self-contained app
builds and a portable `day-one-shortcuts` skill included in `day-one-mac`.
**Architecture:** reviewed sources and a catalogue under `integrations/shortcuts`
feed a bounded build helper. Generated apps contain their code; generated skills
contain their references. The manual guide owns native setup and recovery.
**Tech stack:** AppleScript, Foundation, macOS tools, Node.js and Bash 3.2.
**Spec:** the user approved the five-shortcut proposal in this conversation.
Baseline: `2307c5c` on `codex/ai-manual-setup`, including the uncommitted prior
Finder-shortcuts review. Preserve that work. No commit, push or live installation.

Kind: runbook/reference | Audience: Mac developers and AI clients | Purpose:
create, inspect and maintain selected shortcuts | Non-goals: a setup manager,
optional worktree/remote-site/check apps, live permissions or signed publication.

## Scope and decisions

- Five recipes: Git Clone, Open in VS Code, Open in Warp, Open with VS Code
  Profile, Open Development Workspace. Apps close after dispatch.
- Generated review apps remain outside the checkout. No existing output is
  overwritten. User apps and installed Shortcuts are unchanged.
- Shared folder handling accepts one supplied folder, otherwise Finder's
  selection, otherwise a picker. Cancel is a no-op; multiple/non-folder inputs
  produce a clear error. No keyboard simulation or arbitrary command fields.
- Profile selection reads existing stable VS Code profile metadata and rechecks
  the selected name before dispatch. Unknown metadata stops with manual guidance.
- Warp uses the documented encoded new-tab URI; verify `pwd` manually.
- Ruling: add shared AppleScript and a Node build implementation behind the
  proposed Bash entry point. This avoids copied handlers and allows strict
  catalogue/path validation with the repository's existing Node prerequisite.
- No companion test-driven-development package is installed. Use explicit
  failing fixtures and the repository validation commands.

## Tasks

- [x] Add failing app-build and pure-handler fixtures, then implement the five
  recipes, catalogue and preview/build helper. Preserve clone regressions.
- [x] Add the specialist skill and main-skill routing, catalogue entries and
  source inventories. Regenerate independent packages and test installation.
- [x] Extend the owning manual guide, helper reference and README with native
  creation, AI usage, local/global installation and bounded recovery.
- [x] Run full validation and pinned Skills CLI acceptance. Build review apps,
  inspect bundles, obtain one final review and address material findings.

## Review focus

Check spaces/Unicode and shell/URI metacharacters; absent or renamed profiles;
missing applications and partial workspace opening; occupied output paths and
symlinks; portability without the checkout, skill or personal shortcut IDs.
Tests must not launch live apps, clone repositories or change client profiles.

## Evidence

- Apple documents exporting scripts as apps and running Shortcuts from the CLI.
  Warp documents `warp://action/new_tab?path=`. VS Code documents `--profile`
  creating an empty profile when its name is absent, requiring a read-only guard.
- App fixtures first failed because the builder was absent. Compilation exposed
  two platform assumptions: fresh applets omit CFBundleIdentifier, and the
  executable name differs by compiler output. Read actual metadata when assigning
  IDs and inspecting executables. All five bundles and pure-handler checks passed.
- Independent-package fixtures first failed because shortcut resources were not
  bundled. Added the reviewed assets and specialist; eight copied packages pass
  including preview operation without the checkout or output inside a skill.
- Ruling: VS Code metadata uses an internal format. Fail closed on unknown or
  ambiguous entries and recheck before launch; document the remaining rename race
  rather than promise an atomic guarantee that the CLI does not provide.
- Full validation passed: 31 shell files, 1,434 Markdown files, static sources,
  clean-source/offline-reader fixtures, five compiled apps and eight independent
  packages. Pinned Skills CLI 1.7.4 acceptance passed all 48 client/scope/skill
  installations plus source removal, reinstall, bounded removal and updates.
- The skill-creator validator passed using PyYAML in a temporary virtual
  environment; system Python was unchanged. Actionlint and diff checks passed.
- Built five review apps outside the checkout after inspecting the preview.
  Compilation, bundle signatures and a failed-build retention fixture passed.
  Installed apps, native shortcuts, profiles and permission settings are unchanged.
- Final review identified two material profile-guard defects. The synthetic
  English default name could create an empty profile on a localized installation,
  and name-only metadata could pass even though VS Code skips missing locations.
  Regression fixtures reproduced both before the fix. The chooser now lists only
  registered named profiles and requires a nonempty string location. Built-in
  default selection remains in VS Code's Profiles menu.
- Ruling: accept nested string locations without treating them as filesystem
  paths. Current VS Code metadata includes such locations. The launcher uses
  only registered names; it never reads or writes the stored location itself.
- A read-only local metadata probe reproduced a Standard Additions file-target
  error in the loaded app script. Added an isolated file-reader fixture, observed
  it fail, and used Foundation for explicit UTF-8 file reads and home resolution.
  The file-reader and profile-guard fixtures pass; no app entry point was run.
- Final full validation passed after all corrections. The corrected reader also
  accepted this Mac's metadata in a read-only probe without returning profile
  names or launching VS Code. Both material review findings have regression
  coverage; no remaining material findings were reported.
- Refreshed all review apps, matched their source hashes, checked for personal
  paths and local shortcut IDs, and verified the review ZIP. Removed only this
  task's superseded temporary app builds and validator environment. No live app
  installation, permission change, commit or publication was performed.
