# Optional 10: install AI client payloads

This assisted operation installs only the selected payloads after Phase 8.
Account login, billing, project trust and permissions remain manual. Review
[client choices](../../manual/ai/clients.md) before selecting anything.

## Before you start

Check that Phase 8 is current and choose the intended application owner. Existing
approved external installations remain externally owned.

### Install selected payloads together

After Phase 8, you can use one recoverable operation for selected clients:

```bash
day-one-mac optional --module 10 --plan --clients claude,codex
day-one-mac optional --module 10 --apply --clients claude,codex --app-install-policy homebrew
day-one-mac optional --module 10 --check
```

Supported choices are `claude`, `codex`, `copilot-app`, `copilot-cli`,
`copilot-vscode` and `raycast-ai`. The latter two install only their host
applications, VS Code and Raycast; they do not enable a paid service or install
historical Copilot extensions. Existing official/company-managed installations
are preserved, not transferred to Homebrew.

Review the plan first. Use `--app-install-policy prompt` for an interactive
ownership choice, or install through your approved external route. The default
`check-only` policy stops on missing applications. `--yes` skips selection
confirmation but does not approve an installer or macOS permissions.

Resume interrupted work with `day-one-mac optional --module 10 --resume`,
adding your chosen installation policy when needed. Resume uses the saved
client selection. A passing `--check` means the payloads are present, not that
accounts, permissions, billing or providers work. Continue the client-specific
sign-in steps below; no guide completion marker is written automatically.

## Complete the shared manual action

Follow the [selected client's account setup](../../manual/ai/clients.md) after
installation, then return here. Expected result: the client identifies the
intended account and can perform a harmless read in an approved disposable folder.
Do not infer this result from `--check`, which verifies payload presence.

## Troubleshooting and recovery

If a payload is missing, inspect the chosen app-install policy and installation
owner. If its CLI is not on PATH, open a new shell and check the selected PATH
helper. If login fails, use the client's supported account recovery flow; do not
switch billing credentials merely to clear an error.

Use the [module execution reference](../reference/module-execution.md) to inspect
saved choices and removal boundaries. Account revocation, local client-state
removal and application uninstall are separate actions.
