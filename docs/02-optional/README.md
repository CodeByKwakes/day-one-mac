[← Required setup](../01-required/README.md) · **Optional modules** · [Advanced modules →](../03-advanced/README.md)

# Optional Day One Mac modules

Complete required Phase 8 before adding these modules. Add only what a real
project or workflow needs; skipping every optional module still leaves a
complete development foundation.

| Module | Guide | Automation level | Use it when |
|---:|---|---|---|
| 09 | [Databases](09-databases.md) | Installer: creates/resumes containers and verifies health | A project needs selected containerised databases. |
| 10 | [AI clients](10-ai-agents.md) | App installer plus guided sign-in/configuration | You deliberately want one or more supported AI clients. |
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
