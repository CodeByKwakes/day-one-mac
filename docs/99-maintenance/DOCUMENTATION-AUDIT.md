# Day One Mac documentation audit

**Audit date:** 24 September 2026

**Release baseline:** 1.0.6 and later
**Scope:** every Markdown file, navigation link, setup entry point, phase gate,
application guide, operational guide, Second Brain guide, and Warp workflow in
the standalone Day One Mac project.

This is a current-state report, not a history of earlier playbooks. Upgrade-only
names and aliases are isolated in
[Upgrade notes](../20-reference/UPGRADE-NOTES.md).

## Result

The required path is coherent and executable:

```text
public release installer
  → verified standalone runtime
  → setup wizard
  → Phases 1–8
  → completion report
  → optional Modules 9–14
  → advanced Modules 15–22 when needed
```

The audit found and corrected two blocking classes of issue:

1. Phase 8's chezmoi regression test assumed Python provided `tomllib`. Apple
   can supply an older `python3`, even after uv installs a newer optional Python.
   The test now uses `tomllib` when present and a POSIX `awk` structure check
   otherwise.
2. Upgrade terminology and retired names were repeated across normal setup
   guides. Current guides now teach current commands only; compatibility names
   live on one upgrade-only reference page.

## Authoritative entry points

| User need | Authoritative document or command |
|---|---|
| Download and install | [`README.md`](../../README.md) and [`PORTABLE-COMMAND.md`](../20-reference/PORTABLE-COMMAND.md) |
| Begin a new Mac | [`START-HERE.md`](../START-HERE.md) and `day-one-mac --wizard` |
| Prepare an existing Mac | [`00-preflight/README.md`](../00-preflight/README.md) and `day-one-mac prepare-existing --guided` |
| Understand the complete order | [`PROCESS-OVERVIEW.md`](../PROCESS-OVERVIEW.md) |
| Run one command | [`COMMAND-REFERENCE.md`](../20-reference/COMMAND-REFERENCE.md) |
| Upgrade an earlier installation | [`UPGRADE-NOTES.md`](../20-reference/UPGRADE-NOTES.md) |
| Remove or roll back | [`04-operations/README.md`](../04-operations/README.md) |
| Contribute from a checkout | [`PROJECT-GUIDE.md`](../PROJECT-GUIDE.md) and [`CONTRIBUTING.md`](../../CONTRIBUTING.md) |

## Required phase alignment

| Phase | Script outcome | Primary guide | Gate that marks completion |
|---|---|---|---|
| 1 | Save track, stack, identity, IDE, authentication, macOS-settings and dotfiles choices | [`01-first-boot-and-decisions.md`](../01-required/01-first-boot-and-decisions.md) | All required choices and backup/update confirmation recorded |
| 2 | Verify Apple silicon, Command Line Tools and `/opt/homebrew` | [`02-command-line-foundation.md`](../01-required/02-command-line-foundation.md) | Developer tools and healthy Homebrew available |
| Installation Centre | Resolve ownership and install every required app/tool | [`INSTALLATION-CENTRE.md`](../01-required/INSTALLATION-CENTRE.md) | Required catalogue reports ready, without replacing external installations |
| 3 | Configure selected Git authentication and verify FileVault | [`03-security-and-ssh.md`](../01-required/03-security-and-ssh.md) | Selected provider authentication and FileVault pass |
| 4 | Configure core tools, ghq layout, Git defaults, Raycast and Warp | [`04-core-tools-and-hosting.md`](../01-required/04-core-tools-and-hosting.md) | Track-aware tools and Git settings pass |
| 5 | Establish chezmoi source, shell files, Starship and Homebrew zsh | [`05-dotfiles-and-shell.md`](../01-required/05-dotfiles-and-shell.md) | Managed targets, launcher ownership and login shell pass |
| 6 | Install selected language stacks and pnpm | [`06-language-toolchains.md`](../01-required/06-language-toolchains.md) | Selected runtimes and package managers pass |
| 7 | Verify minimal VS Code base | [`07-vscode-base.md`](../01-required/07-vscode-base.md) | VS Code base is usable; profiles stay optional |
| 8 | Validate project/runtime, capture Brewfile and protect dotfiles | [`08-verify-and-reproduce.md`](../01-required/08-verify-and-reproduce.md) | Complete validator, runtime integrity and selected dotfiles protection pass |

No optional module is required by a Phase 1–8 completion gate. The only
pre-Phase-3 insertion is the Installation Centre because later phases cannot
configure applications that do not exist.

## Terminology and command audit

The following rules now apply across normal user documentation:

- `day-one-mac` is the only primary command name.
- `safety report` is the plain-English name for Stage 0's read-only report.
- `prepare existing Mac` names the Route A/Route B workflow.
- `standalone runtime` means the versioned installation below
  `~/.local/share/day-one-mac`.
- `source checkout` appears only in contributor/development instructions.
- retired command, environment-variable and state-directory names appear only
  where an upgrade or cleanup operation must recognise them.
- normal guides use `day-one-mac …`; direct `scripts/*.sh` commands are limited
  to contributor work, regression testing, or explicitly labelled recovery.
- required work is called a **phase**; optional and advanced work is called a
  **module**.

## Accessibility audit

Each required phase guide contains:

- a plain-English outcome;
- prerequisites and what the user needs before starting;
- numbered steps in execution order;
- an explanation before a command that changes the Mac;
- a verification command or visible result;
- recovery guidance;
- a completion checklist and navigation to the next phase.

The command line uses the same markers throughout:

- `✓` complete;
- `○` pending;
- `⚠` review or manual action;
- `✗` failed gate;
- `🔒` unavailable until prerequisites pass.

The glossary defines terms that a junior developer may not know. Application
ownership distinguishes Homebrew, Company Portal, Mac App Store, manual and
conflicting installations before any package action occurs.

## Safety audit

- The public installer downloads the archive and checksum separately and
  refuses a mismatch.
- `runtime-status` verifies the active runtime's internal manifest.
- A phase is recorded only after every gate passes.
- Existing-Mac cleanup is report-first, backup-gated and preview-first.
- Cleanup never formats or erases a disk.
- Non-Homebrew applications are preserved unless a user selects a separately
  documented removal operation.
- Destructive operations require exact confirmation text and produce recovery
  records.
- Secrets, private keys, cloud-vault contents and knowledge-vault documents are
  never treated as ordinary reproducible configuration.

## Automated checks

Run the same checks used by Phase 8:

```bash
day-one-mac validate
```

Contributors can also run:

```bash
ROOT="$(day-one-mac root)"
"$ROOT/scripts/lint.sh"
"$ROOT/scripts/validate.sh"
```

The validator checks:

- required document presence and phase structure;
- local Markdown paths and section anchors;
- retired path/name leakage into normal guides;
- script executability and Bash syntax;
- wizard/phase/guide command alignment;
- application ownership behaviour;
- Stage 0 safety and resumability;
- 1Password, SSH and secret checks;
- standalone runtime installation and update behaviour;
- shell startup and Homebrew zsh behaviour;
- chezmoi VS Code diff/merge behaviour on both modern and Apple-provided
  Python environments;
- projectless workspace boundaries;
- Raycast, Warp Drive, Obsidian and Notion fixtures.

## Maintainer checklist

Before publishing a release:

- [ ] Update scripts and the owning guide together.
- [ ] Use current command names in normal documentation.
- [ ] Put upgrade-only names in `UPGRADE-NOTES.md`.
- [ ] Run `scripts/lint.sh`.
- [ ] Run `scripts/validate.sh`.
- [ ] Build the release archive and run `shasum -a 256 -c` on its checksum.
- [ ] Extract the archive and verify its internal `SHA256SUMS` manifest.
- [ ] Confirm the published release repeats both checksum checks.

## Current conclusion

The Day One Mac documents, phase runner and standalone runtime describe one
setup system. Phase 8 no longer depends on Python's optional TOML module, and
normal user guides no longer mix current setup instructions with upgrade-only
names. Future drift should be rejected by the validator before a release is
published.

---

[← Maintenance index](README.md) · [Documentation index](../README.md) ·
[Upgrade notes](../20-reference/UPGRADE-NOTES.md)
