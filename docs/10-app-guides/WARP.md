[← Raycast setup](RAYCAST.md) · **Warp setup** · [Keyboard shortcuts](KEYBOARD-SHORTCUTS.md) · [VS Code setup →](VSCODE.md)

# Set up, back up, and restore Warp

**When:** after Phase 4 · **Required app:** yes · **Account, Settings Sync, AI, and Warp Drive:** optional

**Prerequisites completed:** Phase 4 has verified Warp and the required Nerd
Font. Complete Phase 5 before expecting the managed Starship prompt.

## Outcome

Warp opens a zsh session, displays the chezmoi-managed Starship prompt with the
required Nerd Font, and has a deliberate privacy and synchronization policy.
You will also know which parts Warp syncs, which parts need a separate export,
and how to import the optional Day One workflow collection.

Warp is the required graphical terminal. The shell configuration remains owned
by chezmoi, not by Warp. This separation lets the same `.zprofile`, `.zshrc`,
tools, and prompt work in Warp, VS Code, and the built-in Terminal app.

## Step 1 — First launch

1. Open **Warp** from Applications.
2. Decide whether to sign in:

   - Continue without an account for a local terminal-only setup.
   - Sign in only if you want cloud features such as Settings Sync or shared
     Warp Drive objects.

3. Open Warp Settings with `⌘,`.
4. Under **Features → Session**, choose **zsh** as the startup shell for new
   sessions.
5. Open a new tab so the selected shell starts fresh.

Do not ask Warp to replace `.zprofile` or `.zshrc`. Phase 5 manages those files
through chezmoi so they remain reviewable and reproducible.

## Step 2 — Use the shell-owned Starship prompt

Warp can draw its own prompt or display the prompt supplied by the shell.
Day One Mac configures Starship in zsh, so choose the shell-owned option:

1. Open **Settings → Appearance**.
2. Find the prompt or input settings.
3. Select **Shell (PS1)** rather than Warp's native prompt.
4. Search settings for `font` and choose **JetBrainsMono Nerd Font**.
5. Open a new tab.

Run:

```bash
echo "$SHELL"
starship --version
git --version
```

The first command should report zsh, and the prompt should render without empty
squares. If you prefer Warp's native prompt later, you may switch back, but it
will no longer be the same Starship prompt used in other terminals.

## Step 3 — Configure a restrained baseline

Settings names can move between Warp releases. Use the Settings search or the
Command Palette instead of depending on an old screenshot.

| Area | Day One choice | Why |
|---|---|---|
| Startup shell | zsh | Matches the managed shell files |
| Prompt | Shell (PS1) | Uses Starship everywhere |
| Font | JetBrainsMono Nerd Font | Renders prompt icons correctly |
| Start at login | Off initially | A terminal does not need to run continuously |
| Restore windows, tabs, and panes | Off for a clean/minimal setup | Avoids reopening old session output |
| Default editor | VS Code, if requested | Opens files in the required editor |
| AI/agent autonomy | Ask before commands or changes | Keeps terminal actions reviewable |
| Usage and crash reporting | Your explicit privacy choice | Review under Settings → Privacy |

Session restoration stores recent local terminal-session state. Turn it on only
if resuming old tabs is more valuable than beginning with a blank terminal.

## Step 4 — Verify the Day One environment

Open a new Warp tab and run:

```bash
command -v day-one-mac
day-one-mac root
ghq root
chezmoi source-path
```

For a Node stack, also run:

```bash
node --version
npm --version
pnpm --version
```

For a Python stack, run `uv --version`. Commands missing only in Warp usually
mean Warp opened before the shell files changed. Quit Warp completely and open
it again before modifying `PATH`.

## Optional Step 5 — Use AI coding clients from Warp

Warp is the terminal window. Claude Code, Codex, and GitHub Copilot CLI are
three separate command-line applications with separate accounts, settings,
conversation histories, and permission systems. Signing in to Warp does not
sign in to any of them, and choosing one client does not uninstall or disable
the others.

Complete [Optional 10 — AI clients](../02-optional/10-ai-agents.md) first. Install
only the clients selected in the Day One wizard. Confirm what is available in a
new Warp tab:

```bash
command -v claude 2>/dev/null || echo "Claude Code is not installed"
command -v codex 2>/dev/null || echo "Codex CLI is not installed"
command -v copilot 2>/dev/null || echo "GitHub Copilot CLI is not installed"
```

### Start in the correct project

The folder from which a client starts defines the project it can initially see.
Do not start a coding client from your complete home folder. Open the repository
first:

```bash
ghq list
ghq root
```

Choose the repository from `ghq list`, then move into its full path. These are
examples; replace every value inside angle brackets:

```bash
# GitHub track
cd "$HOME/Developer/github.com/<owner>/<repository>"

# Azure DevOps track
cd "$HOME/Developer/dev.azure.com/<organisation>/<project>/_git/<repository>"
```

Before starting an AI client, establish the current state:

```bash
pwd
git status --short --branch
```

Stop if this is the wrong repository or if unexpected existing changes appear.
An AI client must not be asked to overwrite work whose origin you do not
understand.

### Use Claude Code in Warp

Claude Code is the `claude` command. Check its version and authentication:

```bash
claude --version
claude auth status --text
```

If it reports that no account is active, use the interactive login and choose
the intended personal, work, subscription, or usage-billed account:

```bash
claude auth login
```

For the first visit to a repository, start in **plan mode**. Claude can inspect
the project and propose work, but it cannot edit files:

```bash
claude --permission-mode plan
```

Try this first prompt:

```text
Explain what this repository does, identify its main entry points and test
commands, and do not change files or run a deployment.
```

Useful commands inside Claude Code:

| Command | Purpose |
|---|---|
| `/permissions` | Review allow, ask, and deny rules before enabling a tool |
| `/model` | View or change the model for this session |
| `/help` | Show commands supported by the installed release |
| `/rename` | Give a long-running session a recognizable name |

When you are ready to allow reviewed changes, leave the plan-only session and
start the normal approval-based mode:

```bash
claude
```

Ask for one bounded change, review every requested command and edit, then check
the result outside Claude:

```bash
git status --short
git diff --check
git diff
```

Continue the latest conversation for this repository, or choose an older one:

```bash
claude --continue
claude --resume
```

Do not use `bypassPermissions` or a dangerously-skip-permissions option on the
host Mac. Allowing one request is safer than permanently allowing a broad shell
command.

### Use Codex CLI in Warp

Codex CLI is the `codex` command. Confirm the installation and active login:

```bash
codex --version
codex login status
```

If necessary, start the supported browser sign-in. Use the intended ChatGPT
workspace; work and personal accounts can have different policy and usage:

```bash
codex login
```

For the first inspection, explicitly use Codex's read-only sandbox:

```bash
codex --sandbox read-only
```

Try this first prompt:

```text
Review this repository's structure and current Git status. Explain the safest
next development task, but do not edit files or install anything.
```

Use `/permissions` inside Codex to inspect the active sandbox and writable
locations. When you are ready for a bounded implementation, start a session
that can write only within the workspace:

```bash
codex --sandbox workspace-write
```

Keep normal approvals enabled. Do not use `danger-full-access` merely to avoid
a prompt. After the task, inspect the work independently:

```bash
git status --short
git diff --check
git diff
```

Return to a saved conversation or review current work:

```bash
codex resume
codex resume --last
codex review
```

`codex resume --last` is scoped to the current working directory, which is why
moving into the correct repository first matters. The optional OmniRoute
profile does not replace normal Codex login; it is selected explicitly with
`codex --profile omniroute`.

### Use GitHub Copilot CLI in Warp

GitHub Copilot in VS Code and GitHub Copilot CLI are related but different:

- Run `code .` from Warp to open the repository in VS Code and use the built-in
  editor experience.
- Run `copilot` to use the separate terminal client inside Warp.

This guide covers the second option. Confirm its version, then use the supported
OAuth login:

```bash
copilot --version
copilot login
```

The account needs an active Copilot plan. If access comes from an organisation,
that organisation must also allow Copilot CLI. Start the first session in plan
mode:

```bash
copilot --plan
```

Accept the repository trust prompt only after checking `pwd`. Inside Copilot,
confirm the account and permission mode:

```text
/user show
/permissions default
/permissions show
```

Try this first prompt:

```text
Explain this repository and propose one small improvement. Stay in plan mode;
do not edit files, install packages, push, or create a pull request.
```

For normal reviewed work, start `copilot` without the plan flag. When a tool
approval appears, `y` permits that request once and `n` denies it once. Avoid
`/allow-all`, `/yolo`, and broad permanent permissions on the host Mac.

```bash
copilot
```

Continue or choose an earlier session:

```bash
copilot --continue
copilot --resume
```

If the wrong GitHub account is active, use `/user list` and `/user switch`
inside Copilot. Also inspect `COPILOT_GITHUB_TOKEN`, `GH_TOKEN`, and
`GITHUB_TOKEN`: a set environment variable can take precedence over the OAuth
account selected by `copilot login`.

Do not install the retired npm package or rely on the older `gh copilot`
extension when the Day One Brewfile owns the current `copilot-cli` cask.

### Follow the same safe daily loop

Whichever client you choose:

1. Open one Warp tab and move to the repository root.
2. Run `git status --short --branch` before asking for work.
3. Use plan or read-only mode for an unfamiliar repository.
4. Give one bounded outcome and name anything that must not change.
5. Approve only commands and paths you understand.
6. Review `git diff`, run the repository's tests, and inspect generated files.
7. Commit only after the result is understood. Pushing remains a separate,
   deliberate action.

Closing a Warp tab does not necessarily delete a client's saved conversation.
Use that client's resume command after returning to the same repository.

## Decide whether to enable Warp Settings Sync

Settings Sync is optional and requires the intended Warp account.

To enable it:

1. Finish the local baseline above first.
2. Open **Settings → Account**, or search the Command Palette for
   **Settings Sync**.
3. Confirm the signed-in account is personal or work-owned as intended.
4. Enable Settings Sync on this known-good Mac.

The device on which Settings Sync is enabled becomes the source for the synced
settings. Turning it off and on again republishes the current device's settings
as the shared state, so inspect the current setup before toggling it.

Warp syncs most preferences, but it does not currently synchronize every item.
Notable exclusions include custom keybindings, custom themes, device-specific
choices such as the startup shell and default editor, and some
platform-specific settings. A cloud-with-a-line icon identifies a setting that
does not sync.

## Import settings from another terminal — optional

For a clean Day One setup, configure Warp directly. If a trusted iTerm2 Default
profile contains a specific theme or keybinding set you still need:

1. Open the Command Palette.
2. Run **Import External Settings**.
3. Select the iTerm2 **Default** profile.
4. Review the imported theme and keybindings.
5. Reconfirm **zsh**, **Shell (PS1)**, and the Nerd Font.

Warp imports only the iTerm2 Default profile and only supported categories such
as themes and keybindings. It is not a complete terminal-state restore.

## Back up the settings that do not sync

Warp does not provide one portable file containing every application setting.
Use Settings Sync for supported preferences, then separately preserve portable
files under `~/.warp` when they exist.

Quit Warp first, connect the backup volume, and run:

```bash
EXPORT_DIR="/Volumes/<backup-volume>/Day-One-Mac-App-Exports/Warp"
test -d "/Volumes/<backup-volume>" || { echo "Backup volume is not mounted"; exit 1; }
mkdir -p "$EXPORT_DIR"
test ! -d "$HOME/.warp" || ditto "$HOME/.warp" "$EXPORT_DIR/dot-warp"
```

Review this copy before sharing it. Custom themes and launch configurations are
portable, but user-created files can contain machine paths, project names, or
commands. Do not treat a local application-support database as a supported
cross-machine import format.

## Export and import Warp Drive objects — optional

Warp Drive is cloud-backed storage for reusable Workflows, Notebooks, Prompts,
and Environment Variables. It is not required for a working terminal.

To export everything:

1. Open the Command Palette.
2. Run **Export all Warp Drive objects**.
3. Choose this private folder:

   ```text
   /Volumes/<backup-volume>/Day-One-Mac-App-Exports/Warp/Warp-Drive/
   ```

To export one object, right-click it in Warp Drive and choose **Export**.
Workflows export as YAML and Notebooks as Markdown. Prompts can be exported but
cannot currently be imported. Environment Variables export as plain `.env`
files and cannot currently be imported; those files can contain secrets, so
never commit or share them unencrypted.

To import a trusted Workflow or Notebook:

1. Press `⌘\` to open Warp Drive.
2. Right-click the destination or use its plus menu.
3. Choose **Import** and select a supported file or directory.
4. Review every command before running it.

The optional [Day One Warp Drive module](../02-optional/14-warp-drive.md) imports
the validated project workflow bundle. The version-controlled bundle contains
no secrets and keeps cleanup actions in preview mode.

## Use OmniRoute from Warp — optional

Warp can host Claude Code, Codex, or GitHub Copilot CLI sessions that use the
local OmniRoute gateway. It does not need a separate Docker connection:
OrbStack runs the container, and the command launched in Warp calls the
loopback address on this Mac.

Follow [Optional 10A, Step 10A.11](../02-optional/10a-omniroute.md#step-10a11--use-omniroute-from-warp).
Load the endpoint key only into the Warp tab that starts the selected terminal
client. `OMNIROUTE_API_KEY` is an in-memory variable, not a file: do not create
or edit a project `.env` for it. Load it from 1Password using Step 10A.5 each
time a new tab needs it. Do not save the key in Warp Drive, a synced Workflow,
or a shell startup file. Warp's built-in AI has no documented general localhost
OpenAI-compatible endpoint, so it remains separate from this route.

## Change the setup later

- Change the shell in **Settings → Features → Session**; open a new tab to test.
- Change between Warp's prompt and **Shell (PS1)** in Appearance settings.
- Change the font without modifying `.zshrc` or Starship.
- Toggle Settings Sync only from the device whose current settings should win.
- Review Privacy, AI autonomy, and organization-enforced policies after signing
  into a different account or workspace.
- Export Warp Drive before moving or deleting personal objects. Moving an object
  to a team workspace shares it with that team.

For a clean reconfiguration:

1. Export Warp Drive and copy `~/.warp` as described above.
2. Turn Settings Sync off so another device does not immediately repopulate the
   setup.
3. Quit Warp completely.
4. Use the [Day One rollback guide](../04-operations/ROLLBACK.md) if you intend to remove
   Homebrew-owned Warp and archive its known local configuration.
5. Reinstall through the Installation Centre, rerun Phase 4, and repeat the
   small baseline.

Signing out or uninstalling the app should not be assumed to remove cloud data,
team objects, or every local support file.

## Troubleshooting

| Symptom | What to do |
|---|---|
| Warp opens a different shell | Select zsh in Session settings, then open a new tab |
| The prompt differs from VS Code | Choose Shell (PS1), not Warp's native prompt |
| Icons appear as squares | Select JetBrainsMono Nerd Font and restart Warp |
| `pnpm`, `uv`, or `day-one-mac` is missing | Quit and reopen Warp; then compare with a new macOS Terminal session |
| `claude`, `codex`, or `copilot` is missing | Return to Optional 10 and install only that selected client; then completely reopen Warp |
| Browser login opens the wrong account | Sign out or switch in the client, use a private browser window if needed, and confirm the personal/work account before authorising |
| Copilot shows the wrong user after login | Run `/user show`; inspect token environment variables because they can override stored OAuth |
| The client sees the wrong files | Exit, run `pwd`, move to the repository root, and start a new session there |
| A previous conversation is missing | Return to the same repository before using the client's `--continue` or `--resume` command |
| A client wants broad or permanent permission | Deny it and grant only the smallest command/path needed; never use an allow-all mode merely to suppress prompts |
| A change does not appear on another Mac | Check whether the setting has the non-sync icon; back it up separately |
| Settings on all devices changed unexpectedly | The last device to enable Sync became the source; correct one device, then deliberately re-enable from it |
| A Drive import is incomplete | Only supported Workflow and Notebook files can be imported |

## Warp completion checklist 🚦

- [ ] New Warp tabs use zsh.
- [ ] Shell (PS1) displays the Starship prompt.
- [ ] JetBrainsMono Nerd Font renders without missing symbols.
- [ ] Required track and stack commands work in a new tab.
- [ ] Each selected AI client reports a version and shows the intended account.
- [ ] A plan/read-only session succeeds from a test repository before edit mode
  is used.
- [ ] Client permissions remain approval-based; no bypass or allow-all mode is
  the default.
- [ ] VS Code Copilot and the separate `copilot` terminal command are understood
  as different surfaces.
- [ ] Session restoration, privacy reporting, and AI autonomy are deliberate choices.
- [ ] Settings Sync is intentionally on or intentionally off.
- [ ] Non-synced local files and any Warp Drive objects have a private backup.
- [ ] No exported `.env` file is committed or shared.
- [ ] If OmniRoute is used, its key is loaded only into the required terminal
  tab and is absent from Warp Drive and synced settings.

Official references: [Warp installation and setup](https://docs.warp.dev/getting-started/quickstart/installation-and-setup),
[prompt choices](https://docs.warp.dev/terminal/appearance/prompt),
[Settings Sync](https://docs.warp.dev/terminal/more-features/settings-sync),
[migrating from another terminal](https://docs.warp.dev/getting-started/migrate-to-warp), and
[Warp Drive](https://docs.warp.dev/knowledge-and-collaboration/warp-drive).
AI-client behavior is checked against the official
[Claude Code quickstart](https://code.claude.com/docs/en/quickstart),
[Claude Code CLI reference](https://code.claude.com/docs/en/cli-usage),
[OpenAI Codex CLI guide](https://learn.chatgpt.com/docs/codex/cli),
[OpenAI Codex command reference](https://learn.chatgpt.com/docs/developer-commands?surface=cli),
[GitHub Copilot CLI authentication](https://docs.github.com/en/copilot/how-tos/copilot-cli/set-up-copilot-cli/authenticate-copilot-cli),
and the [GitHub Copilot CLI command reference](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference).

---

[← Configure Raycast](RAYCAST.md) · [Configure VS Code →](VSCODE.md) · [Optional Warp Drive →](../02-optional/14-warp-drive.md)
