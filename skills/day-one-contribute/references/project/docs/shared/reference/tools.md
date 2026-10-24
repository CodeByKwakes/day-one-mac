# Reviewed skill helpers

Day One Mac has no global command or runtime installation. Manual setup uses
native application commands. AI-assisted setup can use the following reviewed
helpers when the user approves their scope.

| Helper | Purpose | Writes |
|---|---|---|
| `helpers/vscode/build.cjs` | Generate profile review files or add selected extensions | New export folder; extension installation only when requested |
| VS Code replacement mode | Preview, replace or restore settings and shortcuts | Explicit VS Code files plus private recovery backups |
| `helpers/check.cjs` | Inspect platform and selected tool versions | None; no account or service probes |

Installed skills contain helpers under `references/project/helpers/` and their
configuration beside them. Run them with Node.js 22.20 or newer. Read the helper
source and `--help`; do not edit the installed package or store private notes there.

The [profile helper guide](../tools/vscode-profiles.md) owns preview, installation
and recovery commands. The [verification guide](../verification.md) owns the
functional checks that version detection cannot replace.

From the installed skill directory, a read-only version check is:

```bash
node references/project/helpers/check.cjs
```

Expected result: platform information and tool versions or `not available`.
Missing tools are observations, not permission to install anything. The helper
does not certify account access, database health or security compliance.

Contributors can build the [offline reader](../reading-and-export.md) from the
source tree. No reader service or installed manager is needed. Existing users
can [retire the legacy manager](../migration/remove-legacy-manager.md).

<a id="reviewed-utility-reference"></a>
<a id="prerequisites-and-lifecycle"></a>
<a id="command-families"></a>
<a id="reviewed-capabilities"></a>
<a id="verification-example"></a>
