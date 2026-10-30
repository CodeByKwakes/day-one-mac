# Configure editing and language behaviour

Configure only the selected languages and editing shortcuts after [profile setup](profiles.md). Test changes in disposable files before relying on them in a project.

## 5. Configure import cleanup and keyboard shortcuts

### Choose one import policy

| Action | Effect | Recommended use |
|---|---|---|
| Sort Imports | Sorts imports without removing unused bindings | On explicit save |
| Remove Unused Imports | Removes unused import bindings | Explicit shortcut after a change is ready |
| Organize Imports | Sorts and removes unused imports | Explicit shortcut for final cleanup |
| ESLint fix | Applies the repository's fixable lint rules | On explicit save |

The language service supplies these actions; no import-cleanup extension is
needed. TypeScript treats side-effect imports differently from unused bindings,
but inspect the diff when code intentionally relies on module initialization.
ESLint may also remove imports if the project config enables such a fixer.
Do not add a second import-sort extension or Prettier plugin unless the project
already standardizes on it. Sort Imports requires TypeScript 4.3+; separate
unused-import removal requires 4.9+. Use the project's supported version.
[Current import-action implementation](https://github.com/microsoft/vscode/blob/main/extensions/typescript-language-features/src/languageFeatures/organizeImports.ts).

For automatic full cleanup, replace the action block in each desired language
with this alternative; do not enable both policies:

```json
{
  "[typescript]": {
    "editor.codeActionsOnSave": {
      "source.fixAll.eslint": "explicit",
      "source.sortImports": "never",
      "source.removeUnusedImports": "never",
      "source.organizeImports": "explicit"
    }
  }
}
```

This removes temporarily unused imports when you save. Keep the default
manual-removal policy if you frequently scaffold code before using imports.

### Useful built-in macOS shortcuts

| Task | Default shortcut |
|---|---|
| Command Palette | `⇧⌘P` |
| Open file | `⌘P` |
| New blank file tab | `⌘N` |
| Reopen a closed editor | `⇧⌘T` |
| Switch recent editors | `⌃Tab` |
| Close the active editor | `⌘W` |
| Search workspace symbols | `⌘P`, then type `#` and the symbol name |
| Workspace search | `⇧⌘F` |
| Source Control | `⌃⇧G` |
| Keyboard Shortcuts editor | `⌘K`, then `⌘S` |
| Quick Fix / code action | `⌘.` |
| Rename symbol | `F2` (or `fn+F2` with media-key mode) |
| Go to definition | `F12` (or `fn+F12`) |
| Format document | `⇧⌥F` |
| Toggle line comment | `⌘/` |
| Toggle terminal | `⌃` plus backtick |
| Go back / forward | `⌃-` / `⌃⇧-` |
| Split editor | `⌘\` |

The split-editor key conflicts with 1Password Universal Autofill on some Day
One setups. Resolve that through the [shared shortcut guide](../../apps/keyboard-shortcuts.md)
rather than silently overriding it. Extensions, keyboard layouts, and prior
keymaps can change defaults; inspect **Preferences: Open Keyboard Shortcuts**.

### New file tab shortcut

The shared shortcut assigns `Cmd+T` to a new blank file tab in Default,
Full Stack, AI and Operations. Native `Cmd+N` remains available. This replaces
the default `Cmd+T` workspace symbol search; use `Cmd+P`, then type `#` and a
symbol name for that search. Symbol results require a language provider for
the project. See [workspace symbol navigation](https://code.visualstudio.com/docs/editing/editingevolved#open-symbol-by-name).

1. Activate a selected profile and open **Preferences: Open Keyboard Shortcuts**.

   Expected result: searching `cmd+t` shows its current assignments. Inspect
   any existing custom assignment before replacing it.

2. Open **Preferences: Open Keyboard Shortcuts (JSON)** and back up its contents.
   Merge the [shared keybindings](../../../../shared/reference/vscode-profile-data.md#shared-keybindings)
   into the existing array, then save. Repeat for each selected profile.

   Expected result: each profile has one custom `cmd+t` entry for
   `workbench.action.files.newUntitledFile`. Full Stack and AI retain their
   import-cleanup chords. Generated profile exports include both groups.

3. Press `Cmd+T`, then `Cmd+N`, and close the two blank tabs with `Cmd+W`.

   Expected result: both shortcuts create a new file tab. Confirm that `Cmd+P`
   followed by `#` opens workspace symbol search in a supported project.

To restore the default symbol-search shortcut, remove only the custom `cmd+t`
entry or restore its previous assignment from the backup. If another command
runs, use **Developer: Toggle Keyboard Shortcuts Troubleshooting** and inspect
which binding wins. [Keyboard configuration](https://code.visualstudio.com/docs/configure/keybindings).

### Personal import shortcuts

1. Switch to Full Stack or AI and open **Preferences: Open Keyboard Shortcuts**.
2. Search each chord below and resolve any existing assignment you want to keep.
3. Run **Preferences: Open Keyboard Shortcuts (JSON)** and merge the entries
   into its existing array, then save.

These are suggested personal chords, not defaults:

```json
[
  {
    "key": "cmd+k cmd+i",
    "command": "editor.action.organizeImports",
    "when": "editorTextFocus && !editorReadonly && (editorLangId == typescript || editorLangId == typescriptreact || editorLangId == javascript)"
  },
  {
    "key": "cmd+k cmd+u",
    "command": "editor.action.sourceAction",
    "args": {
      "kind": "source.removeUnusedImports",
      "apply": "first"
    },
    "when": "editorTextFocus && !editorReadonly && (editorLangId == typescript || editorLangId == typescriptreact || editorLangId == javascript)"
  },
  {
    "key": "cmd+k cmd+shift+i",
    "command": "editor.action.sourceAction",
    "args": {
      "kind": "source.sortImports",
      "apply": "first"
    },
    "when": "editorTextFocus && !editorReadonly && (editorLangId == typescript || editorLangId == typescriptreact || editorLangId == javascript)"
  }
]
```

Expected result: on a disposable TS/JS edit, Sort Imports retains unused imports,
Remove Unused Imports removes unused bindings, and Organize Imports does both.
Inspect the diff before keeping a cleanup change.

Do not copy these import bindings into Operations unless it also edits TS/JS.
Use **Developer: Toggle Keyboard Shortcuts Troubleshooting** if a chord invokes
another action. [Keyboard configuration](https://code.visualstudio.com/docs/configure/keybindings).

## 6. Edit environment files

DotENV belongs in Full Stack, Operations and AI. Its language identifier
is `dotenv`; the profile settings cover `.env`, `.env.local`,
`.env.example`, and `development.env`.
[Language manifest](https://github.com/mikestead/vscode-dotenv/blob/master/package.json).

The [canonical profile settings](profiles.md#4-apply-profile-settings)
already disable automatic formatting and suggestions for environment files.
Review that baseline in the active profile rather than applying another copy.

1. Open a non-secret `.env.example` file in one of those profiles.
2. Check the language mode in the status bar and the active formatter settings.
3. Save a disposable edit and inspect the result.

Expected result: DotENV supplies highlighting; automatic formatting and inline
suggestions are disabled. Saving does not load variables into an application.

Keep whitespace and quoting under the application's parser rules. Do not
associate dotenv with shellscript solely to get colors: Docker Compose, dotenv,
and shell parsing are not interchangeable. The language block disables inline
suggestions, but does not prevent an agent or extension from reading a file.
Search exclusions and `.gitignore` are also not agent access controls.

A non-secret example file can describe the expected variables:

```dotenv
# Example values only; replace in your local environment.
API_PORT=3000
DATABASE_URL=postgresql://app:example-only@localhost:5432/app_dev
COMPOSE_PROJECT_NAME=app_dev
```

Keep real values in the project's ignored environment file or selected secret
manager. Use [worktree environment guidance](../../development/worktrees/environment.md)
for per-worktree ports and databases. Do not share one writable database across
branches with incompatible migrations. The NestJS debugger, Prisma CLI, Docker
Compose, and MCP processes each load variables through their own configuration;
opening `.env` in VS Code does not load it into them.

## 7. Configure Angular and NestJS folder icons

Use Material Icon Theme as the single icon theme. Its current verified folder
inventory contains an Angular icon but no NestJS-branded folder entry. Use an
Angular folder icon for frontend folders and a red server icon for NestJS API
folders; this avoids inventing an unsupported `nestjs` folder-icon identifier.
[Folder inventory](https://github.com/material-extensions/vscode-material-icon-theme/blob/main/src/core/icons/folderIcons.ts).

1. Switch to Full Stack and run **Preferences: Open User Settings (JSON)**.
2. Merge the following properties, substituting your folder names and preserving
   any existing custom-clone entries.
3. Save the settings and inspect those folders in the Explorer.

```json
{
  "workbench.iconTheme": "material-icon-theme",
  "material-icon-theme.folders.theme": "specific",
  "material-icon-theme.folders.associations": {
    "frontend": "angular",
    "web": "angular",
    "angular": "angular"
  },
  "material-icon-theme.folders.customClones": [
    {
      "name": "nestjs-api",
      "base": "server",
      "color": "#E0234E",
      "folderNames": ["api", "backend", "nestjs"],
      "rootFolderNames": ["api", "backend", "nestjs"]
    }
  ]
}
```

Expected result: the selected frontend folders use Angular icons; selected API
folders use red server icons. Unrelated folder names keep their existing icons.

Associations match folder names, not framework detection. Every folder named
`api` in this profile gets that icon. Do not map generic `src` to Angular in a
mixed frontend/backend repository. Merge custom clone arrays rather than
replacing existing clones. Folder association names omit the `folder-` prefix.
For a literal NestJS logo, the extension supports user-owned custom SVG folder
icons with separate closed/open assets; follow its published custom-icon
procedure rather than pointing to an arbitrary repository-relative SVG.
[Icon customization](https://github.com/material-extensions/vscode-material-icon-theme#custom-icon-associations).

## 8. Configure Angular HTML highlighting

`ghaschel.vscode-angular-html` supplies highlighting, not Angular diagnostics
or formatting. Keep `angular.ng-template` and Prettier. Leave Angular templates
in their supported HTML language mode; do not invent an `angular-html` language
association. Use it only in Full Stack to avoid changing unrelated profiles.

1. Open an Angular component template.
2. Run **Preferences: Color Theme** and select **Dark Modern**.
3. In Settings, search `@ext:ghaschel.vscode-angular-html` to inspect the options
   exposed by your installed version.
4. For the publisher's screenshot palette, run **vscode-angular-html: Set
   custom color customizations**. Inspect the changed User Settings afterward.
5. Alternatively, use the smaller native color block below. Merge it with
   existing token rules and avoid enabling both competing palettes.

The publisher explicitly states that its screenshot palette is not supplied
by a theme alone. [Extension listing](https://marketplace.visualstudio.com/items?itemName=ghaschel.vscode-angular-html).

```json
{
  "editor.tokenColorCustomizations": {
    "[Dark Modern]": {
      "textMateRules": [
        {
          "scope": "html-template.tag.custom",
          "settings": { "foreground": "#4EC9B0" }
        },
        {
          "scope": "html-template.ng.attributes.input-binding.first-level",
          "settings": { "foreground": "#9CDCFE" }
        },
        {
          "scope": "html-template.ng.attributes.event-handler",
          "settings": { "foreground": "#DCDCAA" }
        },
        {
          "scope": "html-template.ng.control-flow.keyword",
          "settings": { "foreground": "#C586C0" }
        },
        {
          "scope": [
            "html-template.ng.interpolation.begin",
            "html-template.ng.interpolation.end"
          ],
          "settings": { "foreground": "#CE9178" }
        }
      ]
    }
  }
}
```

These are scopes documented by the extension, not guessed setting names.
Use **Developer: Inspect Editor Tokens and Scopes** on a token if the installed
grammar differs. Semantic coloring or later token rules can override colors.
The publisher's configuration documentation is version-sensitive; preserve
your existing palette before using its generation command.
[Scope reference](https://github.com/ghaschel/vscode-angular-html/blob/HEAD/docs/THEMING.md).

Test with a template supported by your project's Angular version:

```html
@if (customer()) {
  <app-customer-card
    [customer]="customer()"
    (saved)="refreshCustomers()"
  />
  <p>{{ customer()?.name }}</p>
}
```

Expected result: distinct colors identify the custom tag, input, event, control-flow keyword,
and interpolation delimiters. If highlighting regresses, disable only this
extension and confirm Language Service diagnostics still work.
