[← Advanced 16](16-brewfile-apps-and-editor.md) · **🤖 ⚙️ Advanced 17** · [Advanced 18 →](18-hosting-identities-azure-and-worktrees.md)

# Advanced 17 - Shell and package automation

**Time:** 45-90 minutes · **Required:** no · **Prerequisites:** required Phases 5-6

## Outcome

The shell gains a small reviewed command surface for ghq navigation, Git,
Homebrew, chezmoi, containers, and project package managers. Helpers detect npm
versus pnpm per repository, never download an undeclared tool silently, and do
not add destructive one-key aliases.

## Executable helper-bundle route

Module 17 generates a versioned bundle without editing or sourcing your shell
startup files. Choose helper groups in a two-column, tab-separated
`helpers.tsv` manifest. A `project` row is optional and requires `packages`:

```text
helper	navigation
helper	packages
project	/Users/your-name/Developer/example-project
```

Replace the example project path, or omit that row. Project inspection needs
the required Node runtime on PATH; the runner never installs it.

```bash
day-one-mac advanced --module 17 --plan --manifest ./helpers.tsv
day-one-mac advanced --module 17 --apply --manifest ./helpers.tsv
day-one-mac advanced --module 17 --check
```

After Phase 8, apply validates zsh syntax and creates the selected files at the
printed artifact path. Review their contents before activating them:

| Bundle | Functions | Behaviour after you deliberately invoke a function |
|---|---|---|
| `navigation.zsh` | `day_one_cdev`, `day_one_gs` | Change to `~/Developer` without requiring ghq, or show Git status |
| `packages.zsh` | `day_one_pm_for_dir`, `day_one_pm_frozen_plan` | Identify npm/pnpm, or print a frozen-install proposal without executing it |

The package inspector parses `package.json` as JSON; it never loads project
JavaScript, runs lifecycle scripts, starts a package manager or fetches tools.
Mixed npm/pnpm locks, a conflicting `packageManager` field, unsupported
Yarn/Bun declarations, symlinked metadata and ambiguous projects are rejected.
A declaration-only project can be classified, but a frozen-install proposal
also requires its matching lockfile. A printed proposal does not verify the
installed manager version or make dependency installation safe automatically.

Choose one configuration owner before copying or sourcing the reviewed files.
For chezmoi-owned shell configuration, make the change through chezmoi rather
than writing a second competing startup block. Existing base aliases are not
replaced; generated functions use the `day_one_` prefix.

`--check` verifies bundle integrity, current bundled-source hashes and any
selected project's manager classification. It does not verify shell activation
or dependency contents. `--resume` creates a new version from the saved
selection and current sources: preview changes before confirming. Failed
validation saves diagnostic evidence without publishing helper files.

The `pm` and `pm_frozen` examples later in this guide are a separate, manually
activated route that actually invokes package managers. They are not generated
or executed by Module 17.

## Complete the shared manual actions

Follow the linked task for the selected actions, verify them, then return here. Manual configuration has one owner; the module records evidence.

| Manual action | Guide |
|---|---|
| 1. Measure before adding plugins | [Open task](../../manual/shell/package-workflows.md#1-measure-before-adding-plugins) |
| 2. Install selected enhancements | [Open task](../../manual/shell/package-workflows.md#2-install-selected-enhancements) |
| 3. Review or extend safe navigation and maintenance aliases | [Open task](../../manual/shell/package-workflows.md#3-review-or-extend-safe-navigation-and-maintenance-aliases) |
| 4. Detect the repository package manager | [Open task](../../manual/shell/package-workflows.md#4-detect-the-repository-package-manager) |
| 5. Enforce reproducible installs | [Open task](../../manual/shell/package-workflows.md#5-enforce-reproducible-installs) |
| 6. Prevent silent package downloads | [Open task](../../manual/shell/package-workflows.md#6-prevent-silent-package-downloads) |
| 7. Audit package-manager drift across ghq repositories | [Open task](../../manual/shell/package-workflows.md#7-audit-package-manager-drift-across-ghq-repositories) |
| 8. Audit repository risk before maintenance | [Open task](../../manual/shell/package-workflows.md#8-audit-repository-risk-before-maintenance) |
| 9. Apply and remeasure | [Open task](../../manual/shell/package-workflows.md#9-apply-and-remeasure) |

## Advanced 17 completion checklist 🚦

- [ ] Startup timing was recorded before and after changes.
- [ ] Every added alias is understandable without memorising hidden side effects.
- [ ] No destructive or approval-bypassing shortcut was added.
- [ ] `pm_for_dir` returns npm and pnpm correctly in both fixtures.
- [ ] Frozen installs use `npm ci` or `pnpm install --frozen-lockfile`.
- [ ] Project versions come from repository declarations, not guide constants.
- [ ] The package-manager and repository audits were reviewed.
- [ ] `.zshrc` and `~/.config/zsh/aliases.zsh` are managed by chezmoi and the final diff is understood.

```bash
day-one-mac advanced --complete 17
```

---

[← Advanced 16](16-brewfile-apps-and-editor.md) · [Continue to Advanced 18 →](18-hosting-identities-azure-and-worktrees.md)
