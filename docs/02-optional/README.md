[← Required setup](../01-required/README.md) · **Optional modules** · [Advanced modules →](../03-advanced/README.md)

# Optional Day One Mac modules

Complete required Phase 8 before adding these modules. Add only what a real
project or workflow needs; skipping every optional module still leaves a
complete development foundation.

| Module | Guide | Use it when |
|---:|---|---|
| 09 | [Databases](09-databases.md) | A project needs selected containerised databases. |
| 10 | [AI clients](10-ai-agents.md) | You deliberately want one or more supported AI clients. |
| 10A | [OmniRoute](10a-omniroute.md) | Selected clients should use an optional local Docker AI gateway. |
| 11 | [MCP servers](11-mcp-servers.md) | A selected AI client needs a reviewed external tool connection. |
| 12 | [VS Code profiles](12-vscode-profiles.md) | Work, personal, or content creation needs isolated editor profiles. |
| 13 | [Enhanced CLI tools](13-enhanced-cli-tools.md) | You want additional terminal utilities beyond the required base. |
| 14 | [Warp Drive](14-warp-drive.md) | You want the validated importable command and workflow collection. |

Open the interactive selector later with:

```bash
day-one-mac optional --guided
```

If the portable command is unavailable:

```bash
cd "$(day-one-mac root)/scripts"
./bootstrap-day-one-mac.sh --optional --guided
```

---

[← Required Phase 8](../01-required/08-verify-and-reproduce.md) · [Advanced modules →](../03-advanced/README.md)
