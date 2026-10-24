[← Advanced index](README.md) · **🤖 ⚙️ Advanced 15** · [Advanced 16 →](16-brewfile-apps-and-editor.md)

# Advanced 15 - Full dotfiles and bootstrap

**Time:** 45-90 minutes · **Required:** no · **Prerequisite:** required Phase 8

## Outcome

The minimal chezmoi source is expanded only for configuration you genuinely
want on another Mac. Machine data stays local, secrets remain excluded, hooks
are idempotent, and a complete inventory explains who owns each target.

Read [Chezmoi concepts and safety boundaries](../../../shared/explanation/chezmoi-boundaries.md)
before expanding ownership. Use the
[command reference](../../../shared/reference/chezmoi-commands.md) when choosing
between `edit`, `add`, `apply`, `merge`, and `forget`.

## Executable inventory and proposal route

Module 15 creates a private inventory and import proposal. It does not copy
dotfile contents, run chezmoi, render templates, execute hooks or change
ownership. Use this route before deciding what to add to your source.

Create `dotfiles.tsv` in an editor, using three tab-separated fields:
target ID, declared owner and absolute source path (or `-`). For example:

```text
gitignore	chezmoi	/Users/your-name/.local/share/chezmoi/dot_gitignore_global
starship	manual	-
```

Replace the example source path with your actual source file. Only include
targets that already exist and that you intend to review:

| Target ID | File below your home directory | Expected chezmoi source suffix |
|---|---|---|
| `gitignore` | `.gitignore_global` | `dot_gitignore_global` |
| `starship` | `.config/starship.toml` | `dot_config/starship.toml` |
| `aliases` | `.config/zsh/aliases.zsh` | `dot_config/zsh/aliases.zsh` |
| `pnpm-defaults` | `.config/pnpm/rc` | `dot_config/pnpm/rc` |

A source may also end in `.tmpl`, but it is never evaluated. Owners are
`chezmoi`, `manual` or `unmanaged`. The latter two require `-` instead of a
source path. Arbitrary targets, credential files and whole directories are
not accepted. Paths through symlinks are rejected.

```bash
day-one-mac advanced --module 15 --plan --manifest ./dotfiles.tsv
day-one-mac advanced --module 15 --apply --manifest ./dotfiles.tsv
day-one-mac advanced --module 15 --check
```

Apply requires recorded Phase 8 completion. At the printed artifact path,
review `evidence.tsv`, `report.md` and `import-proposal.tsv`. The proposal
recommends reviewing an existing source, retaining a manual owner, or reviewing
an unmanaged target before adding it. It is data, not an executable script.

Checks verify that selected files are readable regular files owned by your
current user, and compare their hashes with the snapshot. The manager label is
your declaration, not a discovery of chezmoi's complete ownership graph.
Target/source hashes do not prove that a template renders to the target.
Hashing a file also does not certify that it is secret-free.

Changed, missing or unsafe files make `--check` fail. Review `--plan` before
accepting a new snapshot. `--resume` uses the saved target choices and captures
their current contents as hashes; older versions remain available. Failed
evidence produces a diagnostic snapshot but no import proposal. Complete the
secret review and actual chezmoi changes manually using the sections below.

## Complete the shared manual actions

Follow the linked task for the selected actions, verify them, then return here. Manual configuration has one owner; the module records evidence.

| Manual action | Guide |
|---|---|
| 1. Audit the minimal source first | [Open task](../../manual/shell/dotfile-hardening.md#1-audit-the-minimal-source-first) |
| 2. Use a three-class inventory | [Open task](../../manual/shell/dotfile-hardening.md#2-use-a-three-class-inventory) |
| 3. Keep machine data local | [Open task](../../manual/shell/dotfile-hardening.md#3-keep-machine-data-local) |
| 4. Review global Git ignores and add safe package defaults | [Open task](../../manual/shell/dotfile-hardening.md#4-review-global-git-ignores-and-add-safe-package-defaults) |
| 5. Manage templates without embedding secrets | [Open task](../../manual/shell/dotfile-hardening.md#5-manage-templates-without-embedding-secrets) |
| 6. Add bootstrap hooks carefully | [Open task](../../manual/shell/dotfile-hardening.md#6-add-bootstrap-hooks-carefully) |
| 7. Make personal helpers auditable | [Open task](../../manual/shell/dotfile-hardening.md#7-make-personal-helpers-auditable) |
| 8. Audit the complete source | [Open task](../../manual/shell/dotfile-hardening.md#8-audit-the-complete-source) |

## Advanced 15 completion checklist 🚦

- [ ] The minimal source had a clean, reviewed checkpoint.
- [ ] Every added target has one documented owner.
- [ ] Machine-local data is not in the source repository.
- [ ] Global ignores do not hide project-owned files.
- [ ] Hooks are non-interactive, idempotent, and previewed.
- [ ] Helpers default to safe behaviour and pass syntax checks.
- [ ] No credential file, private key, token, or literal secret is tracked.
- [ ] `chezmoi doctor`, `chezmoi verify`, and the reviewed diff pass.
- [ ] Private-Git mode has the final reviewed commit pushed; or local-only mode
      has a current encrypted backup of `~/.local/share/chezmoi`.

Record completion only after these checks:

```bash
day-one-mac advanced --complete 15
```

---

[← Advanced index](README.md) · [Continue to Advanced 16 →](16-brewfile-apps-and-editor.md)
