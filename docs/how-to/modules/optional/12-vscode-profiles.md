[← Optional modules](README.md) · [VS Code profile setup →](../../apps/VSCODE-PROFILES.md)

# Module 12 retired — VS Code profiles moved

VS Code profiles now have one setup guide:
[Choose and configure VS Code profiles](../../apps/VSCODE-PROFILES.md).
Use it for Default, Full Stack, AI and Operations, or a deliberately chosen
custom profile. Profiles remain optional after the required editor setup.

| Your task | Guide |
|---|---|
| Open VS Code, back up, reset or configure Settings Sync | [VS Code setup and maintenance](../../apps/VSCODE.md) |
| Choose profiles, generate review files or configure them manually | [Profile setup](../../apps/VSCODE-PROFILES.md) |
| Add import shortcuts, icons, worktrees, skills, MCP or shell integration | [Advanced TypeScript reference](../../development/VSCODE-TYPESCRIPT.md) |

## Existing Module 12 users

The separate TSV-based generator has been retired. Module number 12 is
reserved; other modules keep their existing numbers. The old
`day-one-mac optional --module 12` command prints migration guidance and exits
with status 2 without reading a manifest, writing files or opening VS Code.

Existing `artifact-12-selection.tsv`, `artifact-12-current` and
`module-runs/12/` files remain in your Day One Mac state directory. They are
historical artifacts, not current profile verification. The dashboard no
longer counts Module 12, and Module 21 no longer runs its retired check.
No installed VS Code profile, extension or account is removed or migrated.

For the script-assisted route, choose a supported recipe and preview it:

```bash
day-one-mac vscode-profile full-stack --dry-run
```

The main guide explains how to generate and review the full bundle, or create
a custom profile manually. Old TSV selections are not automatically converted;
review their extension IDs against the chosen recipe. Keep any old files you
need, and export active profiles from VS Code before changing them.
