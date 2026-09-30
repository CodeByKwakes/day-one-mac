[← Manual handbook](README.md)

# Chezmoi learning path

Chezmoi stores reviewed master copies of your configuration and applies them
to the files that your tools read. It is not an installer, a password vault,
or a backup of your entire Mac.

## Choose the guide for your task

| Need | Canonical guide | What you learn |
|---|---|---|
| First setup, including private Git or local-only mode | [Setup tutorial](../20-reference/CHEZMOI-SETUP-TUTORIAL.md) | Establish source, local machine data and managed targets; preview, apply, validate and protect them |
| Everyday editing, adding, merging or receiving changes | [Daily workflows](../20-reference/MANAGING-DOTFILES-WITH-CHEZMOI.md) | Choose the right direction of change and avoid overwriting good work |
| An exact command or path | [Command reference](../20-reference/CHEZMOI-COMMAND-REFERENCE.md) | Distinguish inspection, source edits, target writes and combined actions |
| Ownership, templates, secrets and why the boundaries matter | [Concepts and safety boundaries](../20-reference/CHEZMOI-CONCEPTS-AND-BOUNDARIES.md) | Keep one owner per target and separate portable state from private machine state |
| Expansion beyond the required baseline | [Advanced 15](../03-advanced/15-full-dotfiles-and-bootstrap.md) | Audit selected targets, review templates/hooks and expand gradually |
| An unexpected diff or broken shell | [Recovery procedures](../20-reference/MANAGING-DOTFILES-WITH-CHEZMOI.md#recovery) | Preserve evidence, repair the source, then apply only the repaired target |

Beginners: follow the tutorial first, make one ordinary alias change using the
daily guide, and stop there until you have a reason to add templates or hooks.
Experienced maintainers: use the ownership explanation and command reference
before reviewing Advanced 15. Do not treat all advanced examples as defaults.

## What Day One Mac does for you

| Stage | CLI work | Work that remains yours |
|---|---|---|
| Phase 1 | Records your selected dotfile/protection mode | Decide whether to adopt an existing trusted source, create private Git, or use a backed-up local-only source |
| Phase 4 | Installs the selected core tools, including chezmoi | Do not initialise a second source if you already have one |
| Phase 5 | Initialises or adopts the source, prepares the baseline and guides diff/apply gates | Review the complete change before approval; resolve ownership or content conflicts |
| Phase 8 | Checks reproducibility and the selected source protection mode | Review the Brewfile and secret scan; approve private repository access or maintain a tested encrypted backup |
| Module 15 | Hashes selected files and prepares an ownership proposal | Actually edit/add/template/apply targets yourself; proposals do not run chezmoi or hooks |

The script-assisted and entirely manual routes converge on the same ownership
model. If Phase 5 already established your source, use the daily guide rather
than running the manual bootstrap over it again.

## Understand the direction before choosing a command

```text
source files + local machine data → rendered configuration
                                         │
                                      apply
                                         ↓
                              live files used by tools
```

- `edit TARGET` changes the source; `diff TARGET` previews the result.
- `apply TARGET` writes the rendered source to the live target.
- `add TARGET` adopts the live file into the source. It is not the same as
  Git staging and can damage template logic if used blindly.
- `merge TARGET` helps reconcile useful changes on both sides.
- `forget TARGET` stops management while preserving the live file.

Use the daily guide for complete procedures. A private Git commit protects
source history; it does not apply a target. Conversely, applying a target does
not commit or push the source.

## Ownership, templates and secrets

Manage reproducible text such as aliases, Git behaviour and Starship settings.
Keep per-Mac values in the local chezmoi configuration. Keep private keys,
tokens, provider login state and session databases in their secure owning tool.
Do not add the Day One Mac launcher, runtime or `~/.day-one-mac` state.

For private npm feeds, keep credential-bearing `.npmrc` content out of plaintext
source and Git. The `private` filename attribute restricts permissions; it does
not encrypt the file. Review existing ownership before inserting a PAT. See
[Azure Artifacts npm authentication](azure-artifacts-npm.md#if-you-use-chezmoi)
for the manual credential boundary and rotation procedure.

A template is a recipe that renders different text from the same source on
different Macs. Review both the template and its rendered output. Do not adopt
one Mac's rendered file over a template just to obtain an empty diff.
Templates and run scripts may invoke tools: even a preview is not a sandbox
for an untrusted dotfiles repository. Audit an unfamiliar source before using it.

Private Git reduces exposure but is not a secret store. Secret review is needed
before every source commit, not only at initial setup. Never paste a complete
`chezmoi cat`, diff, configuration dump or recovery key into a public issue.

## Completion and recovery

Successful setup means the intended source owns only the intended targets,
rendered changes are understood, the active shell works, and the source has
reviewed private Git history or a tested encrypted backup. An empty diff alone
does not prove safe content or a working shell.

If anything is surprising, stop before applying more files. Use the linked
recovery procedures to preserve the current diff, inspect source versus target,
repair one target, and verify it. Avoid broad resets and broad apply commands.

## Open a specific guide

```bash
day-one-mac docs chezmoi --browser
day-one-mac docs chezmoi-daily --browser
day-one-mac docs chezmoi-reference --browser
day-one-mac docs chezmoi-concepts --browser
```

The [offline HTML and Markdown exports](../20-reference/DOCUMENTATION-COMMANDS.md)
include this learning path and all four guides, not your actual chezmoi source.
