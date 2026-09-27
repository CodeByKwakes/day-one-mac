[← Required setup](../01-required/README.md) · **Optional modules** · [Advanced modules →](../03-advanced/README.md)

# Optional Day One Mac modules

Complete required Phase 8 before adding these modules. Add only what a real
project or workflow needs; skipping every optional module still leaves a
complete development foundation.

| Module | Guide | Automation level | Use it when |
|---:|---|---|---|
| 09 | [Databases](09-databases.md) | Installer: creates/resumes containers and verifies health | A project needs selected containerised databases. |
| 10 | [AI clients](10-ai-agents.md) | Selected payload installer; guided sign-in/configuration | You deliberately want one or more supported AI clients. |
| 10A | [OmniRoute](10a-omniroute.md) | Guided Docker configuration | Selected clients should use an optional local Docker AI gateway. |
| 11 | [MCP servers](11-mcp-servers.md) | Guided client and secret configuration | A selected AI client needs a reviewed external tool connection. |
| 12 | [VS Code profiles](12-vscode-profiles.md) | Guided application UI setup | Work, personal, or content creation needs isolated editor profiles. |
| 13 | [Enhanced CLI tools](13-enhanced-cli-tools.md) | Installer: installs and records selected formulae | You want additional terminal utilities beyond the required base. |
| 14 | [Warp Drive](14-warp-drive.md) | Validated bundle plus guided Warp import | You want the validated importable command and workflow collection. |

Open the interactive selector later with:

```bash
day-one-mac optional --guided
```

The selector saves the plan first. When Databases is selected, it then offers
to run the database installer immediately. Saving a module is not a completion
claim: each module must pass the verification in its guide.

View all Optional and Advanced module states together:

```bash
day-one-mac optional --status
day-one-mac optional --status --audit
```

## Plan, apply and check an executable module

Start with a preview. This example selects two CLI tools; it does not select
every optional package:

```bash
day-one-mac optional --list
day-one-mac optional --module 13 --plan --packages eza,fzf
```

Read the proposed installations. After required Phase 8 is complete, apply the
same selection and confirm the prompt:

```bash
day-one-mac optional --module 13 --apply --packages eza,fzf
day-one-mac optional --module 13 --check
```

Check succeeds only when the selected formulae are installed. Review Module
13 separately for shell integration and Brewfile declarations; this command
does not edit either.

For databases, select only the services your projects need:

```bash
day-one-mac optional --module 09 --plan --services postgres,redis
day-one-mac optional --module 09 --apply --services postgres,redis
day-one-mac optional --module 09 --check
```

Preview never starts OrbStack. Apply may start it and require first-run prompts.
If either installer fails, fix the reported prerequisite and resume its saved
selection:

```bash
day-one-mac optional --module 09 --resume
day-one-mac optional --module 13 --resume
```

Run only the resume command for the module you selected. Existing resources
are preserved; no automatic rollback is attempted after a partial failure.
Plans and checks save nothing. Only apply/resume saves choices and run records.

For AI client payloads, preview your selection, then explicitly choose Homebrew
for any missing applications you want it to manage:

```bash
day-one-mac optional --module 10 --plan --clients claude,codex
day-one-mac optional --module 10 --apply --clients claude,codex --app-install-policy homebrew
day-one-mac optional --module 10 --check
```

Existing external installations are preserved. Check verifies installation,
not sign-in or subscription access; finish the [AI client guide](10-ai-agents.md).
After an interruption, use `--module 10 --resume` with your intended application
policy. The default policy is `check-only`; `--yes` never chooses Homebrew.

Modules 09, 10 and 13 support this interface. Advanced 16 also supports a
[reviewed software selection](../03-advanced/16-brewfile-apps-and-editor.md#executable-selected-payload-route).
Other modules remain guided, even when their guides contain runnable commands. See the
[execution reference](../20-reference/MODULE-EXECUTION.md) for flags, state,
backups, verification limits and the contributor extension contract.

See the [status and audit reference](../20-reference/OPTIONAL-STATUS.md) for
status meanings, strict checks, report locations, and recovery commands.

Resume or inspect Database setup directly:

```bash
day-one-mac databases --saved
day-one-mac databases --saved --status
```

If the command is unavailable, reinstall the public standalone runtime first;
do not make optional work depend on a personal source checkout.

---

[← Required Phase 8](../01-required/08-verify-and-reproduce.md) · [Advanced modules →](../03-advanced/README.md)
