[← Databases](09-databases.md) · **🤖 ⚙️ Optional 10** · [OmniRoute →](10a-omniroute.md)

# Optional 10 — AI clients

**Time:** 10–30 minutes per client · **Required:** no

## Outcome

Only explicitly selected AI clients are installed or enabled. Each uses its
supported account or credential flow, its configuration remains outside public
dotfiles, and the user understands which subscription or usage-billed account
pays for requests.

Before opening a local folder in any client, read
[AI workspaces, projectless tasks, and repository work](../20-reference/AI-WORKSPACES.md).
It distinguishes immutable standalone tasks from repository worktrees, defines
the private client-state boundary, and provides exact launch patterns.

## Step 10.1 — Select clients before installing

Choose any number, including none:

| Client | Surface | Install only when |
|---|---|---|
| Claude Code | Terminal and editor integrations | An Anthropic account is approved for this Mac |
| Codex | Terminal/Desktop/IDE ecosystem | A ChatGPT workspace or OpenAI API account is approved |
| GitHub Copilot app | Standalone desktop agent with parallel sessions | The GitHub account, organisation policy, or own model provider is approved |
| GitHub Copilot in VS Code | Built-in editor experience | The GitHub account has Copilot access |
| GitHub Copilot CLI | Separate terminal client | Copilot is needed outside VS Code |
| Raycast AI | Launcher-wide chat, Quick AI, and AI commands | A paid Raycast plan and an approved provider route are available |

Repository track and AI choice are independent. An Azure-only Mac may use an AI
client without adding GitHub repository hosting, although Copilot itself still
uses a GitHub account.

## Step 10.2 — Claude Code option

Use the common ownership-aware installer. It preserves an existing official or
company-managed `claude` command. When missing, it asks whether to use Homebrew
or another approved installer and rechecks before continuing:

```bash
day-one-mac applications --id claude-code --install-missing
claude --version
claude doctor
```

If the command is not found, confirm `~/.local/bin` is on PATH through the Phase
5 `.zprofile`, then open a new terminal.

Start the client and follow its supported sign-in flow:

```bash
claude
```

Do not export an Anthropic API key globally merely to make the client start.
Choose subscription login or usage-based API billing intentionally.

## Step 10.3 — Codex option

Check for an existing Codex installation, choose its installer only when
missing, and verify it:

```bash
day-one-mac applications --id codex --install-missing
codex --version
```

The recommended personal interactive path is browser sign-in:

```bash
codex login
codex login status
```

Official OpenAI documentation also supports API-key sign-in through stdin for
usage-billed or programmatic work:

```bash
printenv OPENAI_API_KEY | codex login --with-api-key
```

Do not paste a key directly into shell history. ChatGPT sign-in and API-key
sign-in use different account controls and billing. Use only the method intended
for this Mac.

Keep authentication out of dotfiles. If file-based credential storage is used,
`~/.codex/auth.json` must be treated like a password and never committed.

Smoke test inside a disposable repository:

```bash
mkdir -p ~/Developer/_sandbox/codex-check
cd ~/Developer/_sandbox/codex-check
git init
codex
```

Begin with approval prompts enabled and review requested commands.

For work that needs files but is not yet a repository, create one immutable,
uniquely dated task and use it as the Codex working directory. Do not use
`~/.codex` for project files or exported notes:

```bash
task_dir="$(day-one-mac workspace create-task \
  --title 'Codex task' --kind other --client codex \
  --sensitivity private --quiet)"
day-one-mac workspace start-codex "$task_dir"
```

Reference: [official Codex CLI documentation](https://learn.chatgpt.com/docs/codex/cli)
and [OpenAI authentication](https://learn.chatgpt.com/docs/auth).

## Step 10.4 — GitHub Copilot app option

The GitHub Copilot app is a standalone desktop application. It is different
from built-in VS Code Copilot and the terminal-only Copilot CLI, even though it
uses Copilot CLI technology internally.

Day One Mac preserves a valid Company Portal or manually installed copy. When
the app is missing, the ownership-aware installer offers Homebrew's official
`github-copilot-app` cask or another approved installer:

```bash
day-one-mac applications --id copilot-app --install-missing
```

Homebrew installs the current application as `/Applications/GitHub Copilot.app`.
An older official download may exist as `/Applications/Copilot.app`; the
ownership check recognises and preserves that legacy external installation
rather than creating a duplicate. To move an external copy to Homebrew
ownership, uninstall it with its existing owner first, then rerun the command
above.

After installation:

1. Open **GitHub Copilot** from `/Applications`.
2. Choose **Sign in to GitHub**.
3. On a work account, confirm that the organisation allows the separate
   **GitHub Copilot app** policy; the Copilot CLI policy is different.
4. Add one local repository or folder. Start with a disposable repository when
   learning the permission model.
5. Choose **Interactive** or **Plan** for the first session. Review the diff and
   every requested command before allowing changes.
6. Run the ownership check again and confirm it reports either the
   Homebrew-managed current app or a deliberately preserved external copy.

The app can use a Copilot plan or an explicitly configured own model provider.
Provider credentials belong in the system credential store through the app's
settings, never in shell files or chezmoi. Repository connections do not grant
permission to commit, push, or merge without review.

Official reference: [Getting started with the GitHub Copilot app](https://docs.github.com/en/copilot/get-started/quickstart-copilot-app).
Homebrew reference: [`github-copilot-app` cask](https://formulae.brew.sh/cask/github-copilot-app).

## Step 10.5 — GitHub Copilot in VS Code option

Current VS Code provides the Copilot experience without requiring the retired
standalone Copilot Chat extension entry. In VS Code:

1. Open the Accounts menu.
2. Choose the GitHub/Copilot sign-in action.
3. Complete GitHub authorization in the browser.
4. Open Chat and confirm the intended GitHub account is active.
5. Keep tool auto-approval disabled until individual tools have been reviewed.

Do not add duplicate historical Copilot extension identifiers to the Brewfile.

## Step 10.6 — GitHub Copilot CLI option

This is separate from built-in VS Code Copilot:

```bash
day-one-mac applications --id copilot-cli --install-missing
copilot --version
copilot login
```

Do not also install `@github/copilot` globally with npm or pnpm. Homebrew owns
the terminal executable and should perform its upgrades/removal.

## Step 10.7 — Raycast AI option

Raycast itself is already installed by the required Installation Centre. Selecting Raycast AI
does not install a second application; it records that its optional AI features
should be configured.

1. Open **Raycast Settings → AI**.
2. Confirm the signed-in account and paid plan are the ones intended for this
   Mac. Raycast's current AI, Bring Your Own Key, local-subscription, and Custom
   Provider features require a paid plan.
3. Use the [Raycast AI provider decision guide](../10-app-guides/RAYCAST-AI-PROVIDERS.md)
   to choose one starting route: no AI, Raycast's included models, BYOK, a
   custom provider, a local Ollama model, or the [OmniRoute custom
   provider](10a-omniroute.md#step-10a10--connect-raycast-ai).
4. Keep globally allowed tools empty and leave per-tool approval on **Ask**.
5. Send one harmless prompt and verify which provider or account handled it.

Do not configure both a direct provider key and OmniRoute merely for
redundancy; that makes cost and data routing harder to understand. The detailed
launcher baseline remains in the [Raycast application guide](../10-app-guides/RAYCAST.md),
while provider secrets and removal are covered in the
[provider guide](../10-app-guides/RAYCAST-AI-PROVIDERS.md).

## Step 10.8 — Store configuration safely

Configuration may live under client-specific directories such as `.claude`,
`.codex`, or `.copilot`, but authentication files must remain ignored. Before
adding any non-secret preferences to chezmoi:

```bash
find ~/.claude ~/.codex ~/.copilot -maxdepth 2 -type f -print 2>/dev/null
```

Inspect each file. Never add files containing access tokens, refresh tokens,
API keys, session cookies, account IDs that should remain private, or copied
environment secrets.

Repository-level instruction files such as `AGENTS.md` or
`.github/copilot-instructions.md` should be committed with the repository only
when their guidance belongs to all contributors.

Application-managed histories stay with their clients. Save only reviewed
summaries and reusable decisions in an approved knowledge vault. The
[AI workspace guide](../20-reference/AI-WORKSPACES.md) provides the filename, metadata,
promotion, and archive conventions.

## Step 10.9 — Verification and removal

```bash
command -v claude 2>/dev/null || true
command -v codex 2>/dev/null || true
command -v copilot 2>/dev/null || true
codex login status 2>/dev/null || true
```

Raycast has no separate AI command-line executable. Open its model picker and
confirm that only the intended providers and models appear. To disable the
feature without uninstalling the required launcher, turn off AI in Raycast
Settings and remove or disable only the provider credential concerned.

For the GitHub Copilot app, open **Settings**, confirm the intended GitHub
account and model provider, then inspect one harmless session in a disposable
repository. If the provenance report says Homebrew owns it, remove it with:

```bash
brew uninstall --cask github-copilot-app
```

An external copy remains the responsibility of Company Portal or its vendor
installer and is not part of the Homebrew rollback manifest.

To remove clients that the provenance report confirms are Homebrew-owned:

```bash
brew uninstall --cask codex
brew uninstall --cask copilot-cli
```

The broad clean-state script inventories these casks and archives known client
configuration. An externally installed client remains owned by Company Portal
or its vendor installer; review that owner's removal instructions instead.

## Optional completion checklist 🚦

- [ ] Every installed client was explicitly selected.
- [ ] `day-one-mac applications --optional` shows the selected clients and their owners.
- [ ] Each terminal client reports a version; each graphical client opens and shows the intended signed-in account.
- [ ] The active personal/work account is correct.
- [ ] Subscription versus usage-based billing is understood.
- [ ] No authentication file or literal key is tracked by chezmoi or Git.
- [ ] Tool auto-approval remains off until each capability is reviewed.
- [ ] No selected client has duplicate Homebrew and external installation channels.
- [ ] Unselected clients were left unchanged; deselection was not treated as uninstall approval.
- [ ] Projectless file work uses one immutable folder below `~/Developer/_Projectless/tasks/<year>`, not the home directory, parent container, or a client-state directory.
- [ ] Work belonging to an existing repository uses a dedicated Git worktree instead of `_Projectless`.

---

[← Databases](09-databases.md) · [OmniRoute gateway (optional) →](10a-omniroute.md)
