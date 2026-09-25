[← Reference library](README.md) · [Setup tutorial](CHEZMOI-SETUP-TUTORIAL.md) · [Command reference](CHEZMOI-COMMAND-REFERENCE.md)

# Understand chezmoi ownership and safety boundaries

**Document type:** explanation · **Audience:** users deciding what chezmoi should manage and why

Chezmoi gives Day One Mac a reproducible configuration source without turning
the entire home directory into a backup or repository. This document explains
the ownership model behind that decision. For commands, use the
[command reference](CHEZMOI-COMMAND-REFERENCE.md). For procedures, use the
[daily workflows](MANAGING-DOTFILES-WITH-CHEZMOI.md).

## Why Day One Mac uses chezmoi

Shell and tool configuration must satisfy two competing needs:

1. Applications need ordinary files at paths such as `~/.zshrc` and
   `~/.gitconfig`.
2. A new Mac needs reviewed master copies that can be compared, versioned, and
   reproduced safely.

Chezmoi provides both. The source directory holds the desired form; an apply
renders it into the target location. This makes configuration portable without
requiring applications to read files directly from a Git checkout.

## Desired state is not a complete backup

The source should describe reproducible configuration, not capture every file
on the Mac. A useful ownership test is:

> Would this reviewed file help reproduce the same tool behaviour on another
> Mac without copying a credential, cache, installation, or accidental state?

If yes, it may belong in chezmoi. If no, it needs another owner.

| Class | Examples | Correct owner |
|---|---|---|
| Reproducible text configuration | zsh, Git behaviour, Starship, safe aliases | chezmoi |
| Package desired state | `~/Brewfile` | Homebrew interprets it; chezmoi stores it |
| Per-Mac selection | hosting track, stack, account labels | local chezmoi config or Day One Mac state |
| Credential | private key, token, provider login, 1Password database | Keychain, 1Password, or provider CLI |
| Installed runtime | Day One Mac runtime, Node, Python, package binaries | verified installer or package manager |
| Volatile state | caches, browser sessions, logs, `node_modules` | owning application; recreate or back up separately |

Chezmoi and a backup therefore complement one another. Chezmoi rebuilds
selected configuration. A backup protects local-only source, documents, and
other data that desired-state management does not cover.

## Source, target, and rendered content

These three views can differ:

```text
source file + machine data
            │
            ▼
      rendered target
            │ apply
            ▼
       active target
```

- The **source file** can contain template logic and encoded attributes.
- The **rendered target** is what chezmoi calculates for this Mac.
- The **active target** is the file the application currently reads.

`chezmoi diff` compares the rendered state with the active target. `chezmoi
cat TARGET` displays rendered content. `chezmoi source-path TARGET` locates the
master source form.

This distinction explains why blindly running `chezmoi add` is risky for a
template: it can replace carefully designed template logic with one Mac's
rendered output.

## Why machine data stays local

Different Macs can use the same source while supplying different template
inputs. Day One Mac stores those inputs in:

```text
~/.config/chezmoi/chezmoi.toml
```

Typical values include the hosting track, selected development stack, name,
and email. The file is not itself managed because it describes the current
machine.

Local does not mean safe for secrets. Template data can be rendered into
managed files, displayed by a diff, or read by a run script. Credentials
belong in 1Password, Keychain, or the relevant provider's authentication
store. A template should reference a secure owner only when necessary and
should fail clearly rather than produce an empty credential.

## Why the Day One Mac launcher is excluded

The file below is owned by the standalone runtime installer:

```text
~/.local/bin/day-one-mac
```

The installer verifies and activates versioned runtime releases. If chezmoi
also managed the launcher, applying an old dotfiles source could silently
replace the verified launcher and point it at a removed or outdated checkout.

The boundary is deliberate:

- chezmoi owns human-readable configuration;
- the Day One Mac installer owns the launcher and runtime;
- `~/.day-one-mac` stores machine-specific operational state.

One path should have one authoritative owner.

## Why private Git is recommended

Git adds history, review, named rollback points, and recovery on another Mac.
It does not make dotfiles safe to publish. A harmless source today can later
gain an email address, host alias, internal domain, or template reference.

Day One Mac therefore requires a **private** remote in Git mode. Phase 8 checks
that the selected provider repository is private, reachable, clean, and pushed.
The review and secret scan still matter because private access reduces exposure;
it does not correct bad source content.

## What local-only mode changes

Local-only mode changes protection, not chezmoi behaviour. It still has a
source, targets, diffs, adds, edits, and applies. It does not require:

- a Git repository;
- a remote;
- commits; or
- a pushed upstream branch.

The tradeoff is the loss of version history and remote recovery. The complete
`~/.local/share/chezmoi` directory must therefore be included in a tested,
encrypted backup. Selecting local-only does not delete pre-existing `.git`
metadata; automatic deletion would be an unsafe history-destroying operation.

## How Homebrew and chezmoi work together

Homebrew installs packages. A Brewfile declares the intended packages. Chezmoi
stores the reviewed Brewfile so it can be reproduced.

```text
chezmoi source → ~/Brewfile → brew bundle → installed software
```

Chezmoi does not install every package merely because it applies the Brewfile.
Homebrew acts only when `brew bundle` is run directly or by a reviewed hook.
Likewise, dumping the current Homebrew state does not automatically make every
package desirable. Phase 8 avoids `brew bundle dump --force` so an existing
Brewfile is never silently overwritten.

## How 1Password and chezmoi differ

1Password owns secret values, private-key operations, and approvals. Chezmoi
owns non-secret configuration that may refer to those services. For example:

- chezmoi may manage an SSH host block;
- 1Password may provide the private key through its SSH agent;
- chezmoi must not store the private key itself.

The same separation applies to GitHub, Azure, AWS, npm, AI tools, and browser
sessions. Store portable settings; leave authentication state with its owner.

## Templates: portability with added responsibility

Templates are useful when a target must vary by Mac, track, or account. They
also make review less direct because the source is no longer identical to the
target.

Use a template when:

- the same target genuinely needs a small machine-dependent value;
- the input has a clear local owner;
- missing data produces an explicit failure; and
- the rendered output can be inspected safely.

Avoid a template when separate files or application-native profiles make
ownership clearer. More abstraction is not automatically more reproducible.

Before applying a template:

```bash
chezmoi cat TARGET
chezmoi diff TARGET
```

## Run scripts: automation with a larger blast radius

Chezmoi run scripts can install or modify resources outside normal target
files. They belong only in the optional Advanced 15 workflow and must be:

- non-interactive;
- idempotent;
- safe to retry;
- explicit about current-state checks;
- free of literal secrets; and
- previewed with `chezmoi apply --dry-run --verbose`.

Use `run_once_` for a genuinely one-time action and `run_onchange_` only when
source content should trigger a rerun. A run script must not delete user data,
reset application profiles, or hide a destructive action inside an ordinary
dotfile apply.

## The review boundary

The safest unit of work is one named target:

```text
edit source → preview target → apply target → validate owner → commit source
```

Applying every target is reasonable after a complete, understood diff. It is
not a shortcut for resolving uncertainty. When the diff is surprising, stop
and decide which copy contains the desired state before using `add`, `apply`,
or `merge`.

## Common failure patterns

| Failure | Why it happens | Better model |
|---|---|---|
| Editing only `~/.zshrc` | The application writes the target, but source remains authoritative | Edit source first; adopt a target edit only after review |
| Running `chezmoi add` whenever a diff appears | `add` treats the target as desired state | Decide whether source, target, or both contain the correct work |
| Applying the whole source to fix one file | Unrelated drift shares the same apply boundary | Apply the named target |
| Committing machine data | Per-Mac input is mistaken for portable output | Keep it in local config |
| Putting a token in a template | A private repository is mistaken for a secret store | Use the credential owner and runtime references |
| Managing the Day One Mac launcher | Two systems claim the same path | Keep runtime and dotfile ownership separate |
| Treating local-only as temporary | No remote is mistaken for no persistence requirement | Maintain an encrypted backup |
| Using hooks for ordinary configuration | Automation hides external side effects | Prefer declarative targets and explicit package commands |

## A durable mental checklist

Before adding anything to chezmoi, ask:

1. Is it configuration rather than a credential, installation, cache, or data
   file?
2. Will it be useful on another Mac?
3. Does another tool already own it?
4. Can its source and rendered output be reviewed without exposing secrets?
5. Is its machine-specific part local and explicit?
6. Can it be applied and validated as one bounded target?
7. Is the source protected by private Git or a current encrypted backup?

If any answer is unclear, leave the file unmanaged until ownership is decided.

---

[← Reference library](README.md) · [Setup tutorial](CHEZMOI-SETUP-TUTORIAL.md) · [Daily workflows →](MANAGING-DOTFILES-WITH-CHEZMOI.md)
