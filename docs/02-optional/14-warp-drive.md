[← Enhanced CLI tools](13-enhanced-cli-tools.md) · **🤖 ⚙️ Optional 14** · [Advanced modules →](../03-advanced/README.md)

# Optional 14 — Import the Day One Mac Warp Drive bundle

**Time:** 10–20 minutes · **Required:** no · **When:** after Phase 8

## Outcome

Warp contains a personal `Day One Mac` collection with **62 validated
workflows in seven folders** and one searchable command-catalogue Notebook. The
commands follow the new eight-phase project, work from any checkout location,
and expose cleanup only as a preview.

Warp is a required Phase 4 application. Phase 4 accepts a valid copy supplied
by Homebrew, a company portal, or a trusted manual installer; it installs the
Homebrew cask only when Warp is missing and you select Homebrew. Importing this
Warp Drive collection remains optional: the Day One Mac setup, chezmoi,
Starship, pnpm, ghq, and all
verification gates work without the imported workflow objects.

## Step 14.1 — Verify the required Warp application

Phase 4 verifies Warp and records who manages it. Confirm that result before
attempting the optional import:

```bash
day-one-mac applications --id warp
open -a Warp
```

Read `~/.day-one-mac/application-provenance.md`. A Homebrew-managed copy should
also appear as `cask "warp"` in the generated Brewfile. A company-managed or
manual copy is deliberately absent from the Brewfile because Homebrew must not
claim or replace it. For the Homebrew-managed route, verify the desired state:

```bash
rg '^cask "warp"' "$HOME/Brewfile"
brew bundle check --file="$HOME/Brewfile" --no-upgrade
```

## Step 14.2 — Verify the portable command

The early command installer places the `day-one-mac` dispatcher in
`~/.local/bin`; Phase 5 later adopts it into chezmoi. It looks up the current checkout through
`~/.day-one-mac/runtime-root`, so no imported workflow contains a personal
username or absolute repository path.

Open a new terminal and run:

```bash
command -v day-one-mac
day-one-mac root
day-one-mac validate
```

All three commands must succeed before import. If the checkout was moved, run
the setup entry point once from its new location:

```bash
cd /path/to/new/checkout/day-one-mac/scripts
./bootstrap-day-one-mac.sh --guided
day-one-mac root
```

The runner refreshes the project-location record before it checks which phases
are already complete.

## Step 14.3 — Import the directory into Warp Drive

1. Open Warp and sign in to the intended personal or team workspace.
2. Press **Command-Backslash** (`⌘\`) to open Warp Drive.
3. Choose the **plus** menu or right-click the destination, then choose
   **Import**.
4. Select this directory, not one of its child folders:

   ```text
   <checkout>/day-one-mac/warp-drive/Day One Mac
   ```

5. Keep the imported hierarchy when Warp previews it.
6. Confirm the result contains:

   ```text
   Day One Mac
   ├── 00 Day One Mac Command Catalogue
   ├── 01 Setup and Audit            16 workflows
   ├── 02 Safety and Cleanup          5 workflows
   ├── 03 Repositories and Hosting    8 workflows
   ├── 04 Dotfiles                    7 workflows
   ├── 05 Toolchains                 10 workflows
   ├── 06 Homebrew                    6 workflows
   └── 07 AI Workspaces               8 workflows
   ```

The Markdown file imports as a Notebook and each YAML file imports as a
Workflow. The source folder remains useful even if Warp changes its cloud
objects later: it is version-controlled, reviewable, and validated locally.

## Step 14.4 — Run the smoke checks

Search Warp Drive for each of these and insert it into a terminal:

1. `Setup · Show project root`
2. `Setup · Show Day One Mac status`
3. `Setup · Validate Day One Mac project`
4. `Git · Status` from any local Git repository

Read the inserted command before pressing Enter. The first three should work
from any directory because they use the portable dispatcher.

## Step 14.5 — Understand conditional workflows

The import includes all provider and stack entries so the same folder can be
used by every Day One Mac track. Only run those selected for the machine:

| Selection | Applicable workflows |
|---|---|
| Track 1 — GitHub | GitHub and common repository workflows |
| Track 2 — Azure DevOps 🏢 | Azure and common repository workflows |
| Track 3 — GitHub + Azure DevOps 🏢 | Both provider groups |
| Stack `node` or `both` | fnm, npm, and pnpm |
| Stack `python` or `both` | uv/Python |

An unselected client is not installed merely because its workflow is present.

The AI workspace workflows call the shared `day-one-mac workspace` manager.
Task creation uses immutable `tasks/<year>/<timestamp>--<slug>` paths and every
launcher validates `TASK.md` and `AGENTS.md` before starting a client. Folder
creation and listing still work when no AI client is selected; a launch then
reports that the selected client is unavailable. The workflows never install a
client or broaden its permissions.

## Step 14.6 — Use parameterised workflows

The phase, repository, and target workflows contain `{{arguments}}`. When Warp
inserts one:

1. Fill the highlighted value.
2. Use **Shift-Tab** to move between argument positions when needed.
3. Check the completed command.
4. Press Enter only after its target is correct.

Do not save secrets as argument defaults. Provider login commands should use
their normal browser, Keychain, or 1Password authentication flow.

## Step 14.7 — Preserve the cleanup safety boundary

The five cleanup entries are previews. Even the comprehensive entry omits
`--execute`. To actually clean the machine:

1. Open and read [`../ROLLBACK.md`](../04-operations/ROLLBACK.md).
2. Run the appropriate Warp preview.
3. Review every path, package, application, and recovery-archive destination.
4. Run the underlying cleanup script manually with `--execute` and complete
   its typed confirmation.

Do not create a one-click Warp workflow that includes `--execute`. Cleanup can
archive projects, container data, SSH keys, and local 1Password data when those
explicit flags are supplied; it should never be triggered accidentally from
search.

## Step 14.8 — Update an existing import

The version-controlled YAML and Notebook files are the source of truth.
Whenever they change:

```bash
day-one-mac validate
```

Then either update the corresponding Warp objects or remove the old
`Day One Mac` collection and import the directory again. Avoid importing a
second copy into the same location because duplicate names make search results
ambiguous.

## Step 14.9 — Finalise or detach after setup

Two safe workflows help you review post-setup records:

- **Setup · Show finalisation status** reports whether Phase 8 passed and
  whether records were compacted.
- **Setup · Preview post-setup finalisation** shows the compaction plan but
  makes no changes.

Run the actual compaction from a terminal only after reading
[`../FINALIZE.md`](../04-operations/FINALIZE.md). Complete detachment deliberately has no
Warp workflow: it removes or disables the very state and dispatcher on which
the imported collection depends. Remove the collection from Warp Drive first,
then follow the typed-confirmation procedure in the finalisation guide.

## Troubleshooting

| Symptom | Resolution |
|---|---|
| `day-one-mac: command not found` | Run `install-portable-command.sh`, open a new login shell, and confirm `~/.local/bin` is on `PATH` |
| `project location is not recorded` | Rerun `install-portable-command.sh` from the current checkout |
| A provider workflow says its command is missing | Confirm that provider belongs to the selected track; rerun Phase 4 if it does |
| An fnm/pnpm or uv workflow is missing its command | Confirm the selected stack and revalidate Phase 6 |
| An AI launch workflow refuses the current folder | Run a creation workflow, or `cd` into one validated task below `_Projectless/tasks/<year>`; the parent and legacy folders are not accepted automatically |
| An AI launch workflow reports `command not found` | Install/select that client through Optional Module 10; the Warp import never installs clients |
| Import is flat or incomplete | Import the `Day One Mac` directory itself and retain its subfolder hierarchy |
| Duplicate results appear | Remove the older imported collection, validate the source, then import once |
| Finalisation status says Phase 8 is incomplete | Complete or revalidate Phase 8 before compacting records |
| A cleanup preview surprises you | Stop; read `ROLLBACK.md` and do not use `--execute` |

## Optional 14 completion checklist 🚦

- [ ] `day-one-mac root` prints the current checkout.
- [ ] `day-one-mac validate` passes.
- [ ] `day-one-mac applications --id warp` reports a valid owner and Warp opens.
- [ ] Warp shows seven workflow folders, 63 workflows, and one Notebook.
- [ ] The three setup smoke checks work outside the repository.
- [ ] Track- and stack-specific entries are understood.
- [ ] No workflow stores a secret or personal absolute path.
- [ ] Cleanup remains preview-only in Warp.
- [ ] AI launch workflows use the shared workspace manager and refuse the `_Projectless` container root, unrelated folders, and tasks missing their control files.

References: [Warp Drive import and organisation](https://docs.warp.dev/knowledge-and-collaboration/warp-drive),
[YAML workflow format](https://docs.warp.dev/terminal/entry/yaml-workflows), and
[Warp workflows](https://docs.warp.dev/knowledge-and-collaboration/warp-drive/workflows).

---

[← Enhanced CLI tools](13-enhanced-cli-tools.md) · [Advanced modules →](../03-advanced/README.md) · [Review rollback safety](../04-operations/ROLLBACK.md)
