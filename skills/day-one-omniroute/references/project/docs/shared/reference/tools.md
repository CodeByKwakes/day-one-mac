# Reviewed skill helpers

Day One Mac has no global command or runtime installation. Manual setup uses
native application commands. AI-assisted setup can use the following reviewed
helpers when the user approves their scope.

| Helper | Purpose | Writes |
|---|---|---|
| `helpers/vscode/build.cjs` | Generate profile review files or add selected extensions | New export folder; extension installation only when requested |
| VS Code replacement mode | Preview, replace or restore settings and shortcuts | Explicit VS Code files plus private recovery backups |
| `helpers/second-brain/inspect.cjs` | Validate selected repository connections and hash eligible text | None; no network or file bodies in output |
| `helpers/check.cjs` | Inspect platform and selected tool versions | None; no account or service probes |
| `helpers/shortcuts/build-apps.sh` | Preview or compile selected standalone developer apps | New private review folder only; no app installation or launch |

Installed skills contain helpers under `references/project/helpers/` and their
configuration beside them. Run them with Node.js 22.20 or newer. Read the helper
source and `--help`; do not edit the installed package or store private notes there.

The [profile helper guide](../tools/vscode-profiles.md) owns preview, installation
and recovery commands. The [verification guide](../verification.md) owns the
functional checks that version detection cannot replace.
The [shortcut builder reference](../tools/shortcut-apps.md) owns app build options,
output contracts and failure handling.

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

The [Second Brain connection reference](../tools/second-brain-connections.md) owns
private connection fields, exclusions, report output and limitations.
