# Expected file locations

| Location | Owner and purpose |
|---|---|
| Project `.agents/skills/day-one-mac/` | Shared skill installed for selected clients |
| Project `.claude/skills/day-one-mac/` | Claude discovery link, or a copy for Claude-only installation |
| Private setup folder `session/` | User-approved notes and evidence, outside installed skills |
| `~/Library/Application Support/Code/User/` | VS Code User/profile resources |
| User-selected private backup directory | Profile replacement recovery records |
| `~/.local/share/chezmoi/` | Chezmoi source, only if selected |
| User-selected stable plugin artifact root | Current native-plugin marketplace source; keep versioned copies for recovery |
| `~/.local/share/day-one-mac/plugins/` | One possible artifact-root choice; inspect actual client registration before moving it |
| `~/.local/share/day-one-mac/` | May contain current plugin artifacts and historical manager files; never retire this parent as a unit |
| `~/.day-one-mac/` | Historical manager state and recovery evidence; preserve until inspected |

Global client skill locations vary. Inspect the Skills CLI installation summary
and follow [skill verification](../../setup/manual/ai/day-one-skills.md).
Do not move or remove an installation merely because it differs from an example.

Use [legacy removal](../migration/remove-legacy-manager.md) to retire an old
manager while preserving useful configuration and private backups.

<a id="expected-filesystem-layout"></a>
<a id="inspect-your-paths"></a>
<a id="recovery"></a>
