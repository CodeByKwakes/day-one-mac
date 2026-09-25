[← Reference library](README.md) · [Setup tutorial](CHEZMOI-SETUP-TUTORIAL.md) · [Daily workflows](MANAGING-DOTFILES-WITH-CHEZMOI.md)

# Chezmoi command reference for Day One Mac

**Document type:** reference · **Audience:** Day One Mac users who need an exact command or ownership rule

This page describes the chezmoi commands and paths used by Day One Mac. It is
not a setup sequence. Follow the [setup tutorial](CHEZMOI-SETUP-TUTORIAL.md)
for first-time configuration and [daily workflows](MANAGING-DOTFILES-WITH-CHEZMOI.md)
for task-oriented procedures.

## Paths and terms

| Term | Day One Mac meaning | Typical location |
|---|---|---|
| Source directory | Master files, templates, attributes, and run scripts | `~/.local/share/chezmoi` |
| Source file | Encoded or templated form stored in the source | `dot_zshrc`, `dot_gitconfig.tmpl` |
| Target | Active file used by an application | `~/.zshrc`, `~/.gitconfig` |
| Rendered target | Content chezmoi would produce from source and machine data | Displayed by `chezmoi cat TARGET` |
| Machine configuration | Local editor settings and template data | `~/.config/chezmoi/chezmoi.toml` |
| Day One Mac state | Phase choices, manifests, reports, and completion markers | `~/.day-one-mac` |
| Day One Mac runtime | Installed command and versioned project files | `~/.local/bin/day-one-mac`, `~/.local/share/day-one-mac` |

The runtime and Day One Mac state are not part of the chezmoi source.

## Inspection commands

These commands do not apply target changes.

| Command | Result | Use it when |
|---|---|---|
| `chezmoi source-path` | Prints the source directory | You need to inspect or commit the source repository |
| `chezmoi source-path TARGET` | Prints the source path for a managed target | You must locate the real source name without guessing |
| `chezmoi managed -p absolute` | Lists absolute managed targets | You are checking ownership or auditing scope |
| `chezmoi status` | Summarizes source/target state | You need a quick drift view |
| `chezmoi diff TARGET` | Opens the configured VS Code comparison | You want a visual review before apply |
| `chezmoi --use-builtin-diff diff --no-pager TARGET` | Prints a terminal diff | You need copyable output or no graphical editor |
| `chezmoi cat TARGET` | Prints rendered target content | You need to see what apply would write |
| `chezmoi doctor` | Checks chezmoi and environment configuration | Setup, maintenance, or troubleshooting |
| `chezmoi verify` | Checks configured source/target expectations | Final validation and audits |
| `chezmoi state dump` | Shows persistent chezmoi run state | You are reviewing advanced run scripts |

An empty `chezmoi diff` means the rendered source and active targets agree. It
does not prove that the configuration is semantically correct or secret-free.

## Change commands

| Command | What it changes | Choose it when | Main risk |
|---|---|---|---|
| `chezmoi edit TARGET` | Source file or template | You are making a planned managed change | Forgetting to apply and test it |
| `chezmoi add TARGET` | Source, based on the active target | The target contains the reviewed state you want to preserve | Recording stale, secret, or machine-only content |
| `chezmoi apply TARGET` | Active target, based on rendered source | The source is correct and the target should match it | Replacing unrecorded target-only work |
| `chezmoi merge TARGET` | Source through the configured merge tool | Both source and target contain valuable changes | Accepting the wrong merge side or applying unrelated changes |
| `chezmoi forget TARGET` | Removes source ownership without deleting the target | The live file should remain but another owner will manage it | Losing reproducibility if no new owner is assigned |
| `chezmoi update` | Pulls source changes and applies them | You have reviewed and accept a combined pull/apply workflow | Applying remote changes before a separate review |
| `chezmoi init REPOSITORY` | Creates or clones the source | Initial setup or a new Mac | Applying an unreviewed source afterward |
| `chezmoi edit-config` | Machine-local chezmoi configuration | Editor, diff, merge, or per-Mac data must change | Putting secrets into local template data |

Day One Mac recommends a separate Git pull and diff instead of `chezmoi update`
when receiving changes from another Mac:

```bash
SOURCE="$(chezmoi source-path)"
git -C "$SOURCE" pull --ff-only
chezmoi diff
```

This keeps retrieval separate from application.

## Preview and apply options

| Form | Meaning |
|---|---|
| `chezmoi diff TARGET` | Preview one target with configured diff tool |
| `chezmoi diff` | Preview every changed managed target |
| `chezmoi apply TARGET` | Apply one target |
| `chezmoi apply TARGET1 TARGET2` | Apply only the named set |
| `chezmoi apply --dry-run --verbose` | Preview file operations and advanced run-script activity |
| `chezmoi apply` | Apply all current source differences; use only after reviewing the complete diff |

Prefer a named target while diagnosing or making one change. A broad apply is
appropriate only when the complete current diff has been reviewed.

## Required managed targets

Phase 5 requires these targets:

| Target | Owner and purpose |
|---|---|
| `~/.zprofile` | Login-shell entry point; loads shared PATH configuration |
| `~/.zshrc` | Interactive zsh configuration |
| `~/.config/zsh/path.zsh` | Shared Homebrew, local-bin, and selected toolchain PATH |
| `~/.config/zsh/aliases.zsh` | Safe Day One Mac, Git, chezmoi, and Homebrew aliases |
| `~/.gitconfig` | Git identity, includes, signing, and global behaviour |
| `~/.gitignore_global` | Portable macOS and editor artefact ignores |
| `~/.ssh/config` | Reviewed provider host configuration; comment-only is valid for HTTPS-only setups |
| `~/.config/starship.toml` | Starship prompt configuration |

Phase 8 also requires the reviewed `~/Brewfile` to be managed.

## Targets deliberately excluded

| Path or class | Reason |
|---|---|
| `~/.local/bin/day-one-mac` | Owned by the checksum-verified standalone runtime |
| `~/.day-one-mac` | Machine state, reports, choices, and recovery manifests |
| `~/.config/chezmoi/chezmoi.toml` | Per-Mac input, not portable output |
| SSH private keys and 1Password data | Secret material belongs to the credential owner |
| `~/.config/gh/hosts.yml`, `~/.azure`, `~/.aws` | Provider authentication state |
| `.env`, auth JSON, tokens, cookies, caches | Secret or volatile state |
| Runtime installations and `node_modules` | Recreated by their package/runtime owner |

## Day One Mac aliases

Phase 5 places these convenience aliases in
`~/.config/zsh/aliases.zsh`:

| Alias | Expansion | Purpose |
|---|---|---|
| `cm` | `chezmoi` | Short command prefix |
| `cmstatus` | `chezmoi status` | Quick drift summary |
| `cmdiff` | `chezmoi diff` | Configured visual diff |
| `cmdifftext` | `chezmoi --use-builtin-diff diff --no-pager` | Terminal-only diff |
| `cmmerge` | `chezmoi merge` | Configured merge workflow |
| `cmverify` | `chezmoi verify` | Verify managed state |
| `cmdoctor` | `chezmoi doctor` | Diagnose chezmoi configuration |

Aliases do not add confirmation or safety behaviour. They are exact shortcuts
for the commands shown.

## Choose the correct command

| Current situation | Command sequence |
|---|---|
| Plan a new change | `chezmoi edit TARGET` → `chezmoi diff TARGET` → `chezmoi apply TARGET` |
| Source is correct; target is stale | `chezmoi diff TARGET` → `chezmoi apply TARGET` |
| Target has a reviewed change to keep | `chezmoi diff TARGET` → `chezmoi add TARGET` → inspect source Git diff |
| Both copies contain useful work | `chezmoi merge TARGET` → `chezmoi diff TARGET` → `chezmoi apply TARGET` |
| Stop managing but keep the live file | `chezmoi forget TARGET` → verify target → commit source removal |
| Find the master copy | `chezmoi source-path TARGET` |
| Inspect rendered content | `chezmoi cat TARGET` |
| Receive a private remote change | Git `pull --ff-only` in source → `chezmoi diff` → named applies |
| Audit the whole setup | `chezmoi doctor` → `chezmoi managed` → `chezmoi diff` → `chezmoi verify` |

## Day One Mac commands related to chezmoi

| Command | Relationship |
|---|---|
| `day-one-mac setup --phase 05` | Creates, adopts, applies, and verifies the required baseline |
| `day-one-mac setup --phase 05 --dotfiles-repo URL` | Uses an existing private source |
| `day-one-mac setup --phase 05 --new-dotfiles --dotfiles-versioning git` | Creates or retains a new source requiring private Git in Phase 8 |
| `day-one-mac setup --phase 05 --local-dotfiles` | Selects the local-only protection gate |
| `day-one-mac shell-status` | Verifies shell paths, startup files, aliases, and tools |
| `day-one-mac setup --phase 08` | Adds Brewfile desired state and checks source protection |
| `day-one-mac advanced --complete 15` | Records completion of the optional expanded-dotfiles module |
| `day-one-mac advanced-audit` | Includes chezmoi and Brewfile drift in the private audit |

## Routine health check

```bash
chezmoi doctor
chezmoi status
chezmoi --use-builtin-diff diff --no-pager
chezmoi verify
day-one-mac shell-status
```

Private-Git mode should also have a clean, pushed source repository. Local-only
mode should have a recent, tested encrypted backup.

---

[← Reference library](README.md) · [Daily workflows](MANAGING-DOTFILES-WITH-CHEZMOI.md) · [Concepts and boundaries →](CHEZMOI-CONCEPTS-AND-BOUNDARIES.md)
