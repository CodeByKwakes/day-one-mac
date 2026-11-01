# Install and configure selected AI clients

Choose only approved clients and accounts. A CLI, editor extension and desktop
app are distinct surfaces; installing one does not prove the others are signed
in. Check the provider's account, billing and organisation requirements before
sending project content.

## Before you start

For assistance before the toolchain is installed, begin with the
[optional AI setup checkpoint](setup-assistant.md). It needs only one client
and does not depend on Homebrew or Node. Return here for additional clients.

Read [AI workspace boundaries](../development/ai-workspaces.md). Confirm the
selected Node/shell prerequisites where applicable. Reuse approved existing
installations, including company-managed ones. The following Homebrew casks are
the repository's selections, not a requirement to replace another valid owner:

| Client | Check first | Install only if selected, absent and Homebrew-owned |
|---|---|---|
| Claude Code CLI | `claude --version` | `brew install --cask claude-code` |
| Codex CLI | `codex --version` | `brew install --cask codex` |
| GitHub Copilot CLI | `copilot --version` | `brew install --cask copilot-cli` |
| GitHub Copilot app | Inspect the approved application | `brew install --cask github-copilot-app` |
| Copilot in VS Code | Inspect existing AI features and account | Use the editor's setup flow; no duplicate extension installation |
| Raycast AI | Inspect Raycast and account entitlement | Configure the existing app's approved provider |

Install one selected missing payload, then verify its version or launch. Desktop
apps and remote features have their own account/availability requirements.
Versioned settings examples are recommendations; follow the installed client's
schema if a field is unavailable.

Complete only the client sections you selected, in any order. Finish with the
shared configuration and verification sections.

## Configure Claude Code

Check the selected command after installation:

```bash
claude --version
claude doctor
```

If the command is not found, confirm `~/.local/bin` is on PATH through your shell PATH helper, then open a new terminal.

Start the client and follow its supported sign-in flow:

```bash
claude
```

Do not export an Anthropic API key globally merely to make the client start.
Choose subscription login or usage-based API billing intentionally.

## 1. Codex option

Check for an existing Codex installation, choose its installer only when
missing, and verify it:

```bash
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
cd "$HOME/Documents/AI Tasks/YOUR-TASK"
codex
```

Reference: [official Codex CLI documentation](https://learn.chatgpt.com/docs/codex/cli)
and [OpenAI authentication](https://learn.chatgpt.com/docs/auth).

## 2. GitHub Copilot app option

The GitHub Copilot app is a standalone desktop application. It is different
from built-in VS Code Copilot and the terminal-only Copilot CLI, even though it
uses Copilot CLI technology internally.

Day One Mac preserves a valid Company Portal or manually installed copy. Reuse an
approved existing copy. If the application is absent and Homebrew is your
selected owner, install it:

```bash
brew install --cask github-copilot-app
brew list --cask --versions github-copilot-app
```

Expected result: Homebrew lists the installed cask and the app opens from
`/Applications/GitHub Copilot.app`. An older official copy can be named
`Copilot.app`; inspect Applications and your organisation's software catalogue
before installing. Do not create a second installation to change its owner.

After installation:

1. Open **GitHub Copilot** from `/Applications`.
2. Choose **Sign in to GitHub**.
3. On a work account, confirm that the organisation allows the separate
   **GitHub Copilot app** policy; the Copilot CLI policy is different.
4. Add one local repository or folder. Start with a disposable repository when
   learning the permission model.
5. Choose **Interactive** or **Plan** for the first session. Review the diff and
   every requested command before allowing changes.
6. Confirm the selected account and open a harmless local task. Record whether
   Homebrew, Company Portal or the vendor installer owns this copy.

The app can use a Copilot plan or an explicitly configured own model provider.
Provider credentials belong in the system credential store through the app's
settings, never in shell files or chezmoi. Repository connections do not grant
permission to commit, push, or merge without review.

Official reference: [Getting started with the GitHub Copilot app](https://docs.github.com/en/copilot/get-started/quickstart-copilot-app).
Homebrew reference: [`github-copilot-app` cask](https://formulae.brew.sh/cask/github-copilot-app).

## 3. GitHub Copilot in VS Code option

Current VS Code provides the Copilot experience without requiring the retired
standalone Copilot Chat extension entry. In VS Code:

1. Open the Accounts menu.
2. Choose the GitHub/Copilot sign-in action.
3. Complete GitHub authorization in the browser.
4. Open Chat and confirm the intended GitHub account is active.
5. Keep tool auto-approval disabled until individual tools have been reviewed.

Do not add duplicate historical Copilot extension identifiers to the Brewfile.

## 4. GitHub Copilot CLI option

This is separate from built-in VS Code Copilot:

```bash
copilot --version
copilot login
```

Do not also install `@github/copilot` globally with npm or pnpm. Homebrew owns
the terminal executable and should perform its upgrades/removal.

## 5. Raycast AI option

Install or reuse Raycast through the [Raycast guide](../apps/raycast.md) first.
Its AI features use the same application and have separate account requirements.

1. Open **Raycast Settings → AI**.
2. Confirm the signed-in account and paid plan are the ones intended for this
   Mac. Raycast's current AI, Bring Your Own Key, local-subscription, and Custom
   Provider features require a paid plan.
3. Use the [Raycast AI provider decision guide](../apps/raycast-ai-providers.md)
   to choose one starting route: no AI, Raycast's included models, BYOK, a
   custom provider, a local Ollama model, or the [OmniRoute custom
   provider](omniroute.md#11-connect-raycast-ai).
4. Keep globally allowed tools empty and leave per-tool approval on **Ask**.
5. Send one harmless prompt and verify which provider or account handled it.

Do not configure both a direct provider key and OmniRoute merely for
redundancy; that makes cost and data routing harder to understand. The detailed
launcher baseline remains in the [Raycast application guide](../apps/raycast.md),
while provider secrets and removal are covered in the
[provider guide](../apps/raycast-ai-providers.md).

## 6. Store configuration safely

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
[AI workspace guide](../development/ai-workspaces.md) provides the filename, metadata,
promotion, and archive conventions.

## 7. Verification and removal

```bash
command -v claude 2>/dev/null || true
command -v codex 2>/dev/null || true
command -v copilot 2>/dev/null || true
codex login status 2>/dev/null || true
```

Raycast has no separate AI command-line executable. Open its model picker and
confirm that only the intended providers and models appear. To disable the
feature without uninstalling the launcher, turn off AI in Raycast
Settings and remove or disable only the provider credential concerned.

For the GitHub Copilot app, open **Settings**, confirm the intended GitHub
account and model provider, then inspect one harmless session in a disposable
repository. If `brew list --cask --versions github-copilot-app` confirms Homebrew ownership,
remove it with:

```bash
brew uninstall --cask github-copilot-app
```

An external copy remains the responsibility of Company Portal or its vendor
installer and is not part of the Homebrew rollback manifest.

For each selected CLI, confirm its cask appears in `brew list --cask`. Run only
the corresponding removal command:

```bash
brew uninstall --cask codex
brew uninstall --cask copilot-cli
```

For native or company-managed clients, follow the existing owner's removal
instructions. Preserve reviewed configuration separately; a package uninstall
is not a backup of client settings.
