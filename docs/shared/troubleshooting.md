# Find the right troubleshooting procedure

Start with the first failing action and retain its exact non-secret error.
Do not repeat later steps until the owning task's verification succeeds. This
index points to remedies; it does not maintain a second copy of them.

| Symptom | Owning guide |
|---|---|
| Unsupported OS, translated terminal or missing approval | [Prerequisites](prerequisites.md) |
| Apple tools or Homebrew not available | [Manual foundation](../setup/manual/homebrew.md) |
| Installer/runtime command unavailable | [Assisted runtime](tools/runtime.md) |
| Existing Mac backup or preparation blocked | [Assisted preparation](reference/tools.md) or [manual backup destination](../setup/manual/preparation/encrypted-backup.md) |
| SSH key, host fingerprint or signing problem | [SSH recovery](../setup/manual/security/ssh-signing-and-recovery.md) |
| HTTPS login works in CLI but Git fails | [HTTPS Git](../setup/manual/security/https-git.md) |
| Private npm feed rejects credentials | [Azure Artifacts](../setup/manual/git/azure-artifacts-npm.md) |
| Shell starts slowly, wrong PATH, arrows ignore typed prefix | [Zsh](../setup/manual/shell/zsh.md) |
| Chezmoi would overwrite a change | [Chezmoi maintenance and recovery](../setup/manual/shell/chezmoi.md) |
| Wrong Node, pnpm or Python | [Languages](../setup/manual/languages.md) |
| VS Code formatting, profiles or Sync conflict | [VS Code](../setup/manual/editors/vscode.md) |
| Assisted profile replacement/restore conflict | [Profile operation](tools/vscode-profiles.md) |
| Database connection, role, TLS or recovery failure | [Database operations](../setup/manual/databases/operations.md) |
| Agent cannot find a skill or uses the wrong instructions | [Instructions and skills](../setup/manual/ai/instructions-agents-skills.md) |
| MCP server unavailable in a client | [MCP](../setup/manual/ai/mcp.md) or [Docker MCP](../setup/manual/ai/mcp-docker.md) |
| Worktree already checked out or environment clashes | [Worktree troubleshooting](../setup/manual/development/worktrees/troubleshooting.md) |
| Obsidian/Notion capture or recovery problem | [Second Brain](../setup/manual/second-brain/README.md) |
| Assisted selection or saved state is stale | [Module execution](reference/module-execution.md) and [readiness](reference/workstation-readiness.md) |
| Need to undo recorded changes | [Assisted recovery](reference/tools.md) or [manual restore](../setup/manual/backup-and-restore.md) |

## Information to retain

Record the task, selected route, relevant versions, attempted action, exit status
and first error. Include whether the device is managed and which owner installed
the tool. Remove tokens, private hostnames, account details and personal paths
before sharing evidence. For managed network/control failures, send the evidence
to the responsible IT owner through the approved channel.
