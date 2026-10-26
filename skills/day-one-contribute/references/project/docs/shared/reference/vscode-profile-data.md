# VS Code profile configuration reference

Generated from the versioned [profile configuration](../../../config/profiles/vscode/profiles.json).
Use the [profile guide](../../setup/manual/editors/vscode.md) for selection, import and verification.
Maintainers update this page with `node tools/sync-vscode-reference.cjs`; edit the configuration source first.

## Shared settings

```json
{
  "files.autoSave": "off",
  "files.insertFinalNewline": true,
  "files.trimTrailingWhitespace": true,
  "editor.fontFamily": "'JetBrainsMono Nerd Font', Menlo, monospace",
  "editor.fontSize": 14,
  "editor.minimap.enabled": false,
  "editor.renderWhitespace": "selection",
  "editor.rulers": [
    100
  ],
  "editor.bracketPairColorization.enabled": true,
  "editor.guides.bracketPairs": true,
  "editor.stickyScroll.enabled": true,
  "editor.linkedEditing": true,
  "editor.formatOnSave": false,
  "editor.formatOnPaste": false,
  "editor.detectIndentation": true,
  "explorer.compactFolders": false,
  "explorer.openEditors.visible": 9,
  "workbench.editor.labelFormat": "medium",
  "workbench.editor.enablePreview": false,
  "git.autofetch": true,
  "git.confirmSync": true,
  "git.enableSmartCommit": false,
  "git.suggestSmartCommit": false,
  "git.detectWorktrees": true,
  "git.detectWorktreesLimit": 30,
  "scm.alwaysShowRepositories": true,
  "workbench.colorTheme": "Dark Modern",
  "workbench.iconTheme": "material-icon-theme",
  "terminal.integrated.profiles.osx": {
    "Zsh — development": {
      "path": "/bin/zsh",
      "args": [],
      "icon": "terminal"
    },
    "Zsh — login diagnostics": {
      "path": "/bin/zsh",
      "args": [
        "-l"
      ],
      "icon": "terminal"
    }
  },
  "terminal.integrated.defaultProfile.osx": "Zsh — development",
  "terminal.integrated.shellIntegration.enabled": true,
  "terminal.integrated.suggest.enabled": true,
  "terminal.integrated.suggest.upArrowNavigatesHistory": true,
  "terminal.integrated.inheritEnv": true,
  "terminal.integrated.fontFamily": "JetBrainsMono Nerd Font, monospace",
  "terminal.integrated.fontSize": 13,
  "terminal.integrated.scrollback": 10000,
  "terminal.integrated.copyOnSelection": false,
  "terminal.integrated.enablePersistentSessions": true,
  "terminal.external.osxExec": "Warp.app",
  "chat.tools.global.autoApprove": false,
  "chat.tools.terminal.enableAutoApprove": false,
  "chat.mcp.gallery.enabled": true,
  "gitlens.ai.generateCommitMessage.customInstructions": "Use Conventional Commits: type(scope): description, omitting the scope when unnecessary. Choose feat, fix, docs, refactor, perf, test, build, ci, chore, style, or revert according to the actual changes and repository conventions. Write a specific, imperative subject, preferably within 72 characters, without a trailing period. For substantial changes, add a blank line and a concise body explaining what changed and why, using only evidence from the diff and supplied context. Keep simple changes to a subject alone. Do not invent motivations, test results, issue references, or compatibility guarantees. Use ! and a BREAKING CHANGE footer only for actual breaking changes. Return only the commit message.",
  "github.copilot.chat.commitMessageGeneration.instructions": [
    {
      "text": "Use Conventional Commits: <type>(<optional scope>): <description>. Choose feat, fix, docs, refactor, perf, test, build, ci, chore, or revert based on the actual change. Follow repository conventions when available."
    },
    {
      "text": "Write an imperative, specific subject, preferably within 72 characters, without a trailing period. Describe the main outcome rather than listing filenames. Use a scope only when it makes the affected area clearer."
    },
    {
      "text": "For substantial changes, add a blank line and a concise body explaining the problem, what changed, and why. Include meaningful behavior changes or limitations. Keep simple changes to a subject alone."
    },
    {
      "text": "Describe only changes included in this commit. Do not invent motivations, test results, issue references, or compatibility guarantees. Mention validation only when its execution and outcome are known."
    },
    {
      "text": "Use ! and a BREAKING CHANGE footer only for actual breaking changes. Include issue references only when supplied. Return only the commit message, without Markdown fences or commentary."
    }
  ],
  "markdownlint.run": "onSave",
  "markdownlint.configFile": "${userHome}/.config/markdownlint/config.json",
  "markdown.extension.toc.updateOnSave": false,
  "markdown.extension.tableFormatter.enabled": false,
  "[markdown]": {
    "editor.defaultFormatter": "DavidAnson.vscode-markdownlint",
    "editor.formatOnSave": true,
    "editor.wordWrap": "on",
    "files.trimTrailingWhitespace": false
  },
  "[json]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true
  },
  "[jsonc]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true
  }
}
```

## Personal Markdown rules

Save this separate JSON object to `~/.config/markdownlint/config.json`, following the [Markdown setup steps](../../setup/manual/editors/vscode.md#markdown-formatting).
Profile exports and Settings Sync do not include this external file; back it up separately.

```json
{
  "MD060": {
    "style": "compact",
    "aligned_delimiter": false
  }
}
```

## Default

| Extension ID | Selection |
| --- | --- |
| `esbenp.prettier-vscode` | Recommended |
| `editorconfig.editorconfig` | Recommended |
| `pkief.material-icon-theme` | Recommended |
| `yzhang.markdown-all-in-one` | Recommended |
| `davidanson.vscode-markdownlint` | Recommended |
| `tomoki1207.pdf` | Optional |
| `grapecity.gc-excelviewer` | Optional |
| `natqe.reload` | Optional |

### Default overrides

```json
{
  "workbench.colorCustomizations": {
    "titleBar.activeBackground": "#30343B",
    "titleBar.activeForeground": "#FFFFFF"
  },
  "github.copilot.enable": {
    "*": false
  }
}
```

## Full Stack

| Extension ID | Selection |
| --- | --- |
| `esbenp.prettier-vscode` | Recommended |
| `editorconfig.editorconfig` | Recommended |
| `pkief.material-icon-theme` | Recommended |
| `yzhang.markdown-all-in-one` | Recommended |
| `davidanson.vscode-markdownlint` | Recommended |
| `angular.ng-template` | Recommended |
| `ghaschel.vscode-angular-html` | Recommended |
| `nrwl.angular-console` | Recommended |
| `dbaeumer.vscode-eslint` | Recommended |
| `prisma.prisma` | Recommended |
| `eamodio.gitlens` | Recommended |
| `openai.chatgpt` | Recommended |
| `anthropic.claude-code` | Recommended |
| `omarbanat.goodprompts` | Recommended |
| `mikestead.dotenv` | Recommended |
| `redhat.vscode-yaml` | Recommended |
| `ms-azure-devops.azure-pipelines` | Recommended |
| `ms-azuretools.vscode-containers` | Recommended |
| `ms-ossdata.vscode-pgsql` | Recommended |
| `sleistner.vscode-fileutils` | Recommended |
| `bradlc.vscode-tailwindcss` | Recommended |
| `imgildev.vscode-auto-barrel` | Recommended |
| `tomwhite007.rename-angular-component` | Recommended |
| `orta.vscode-jest` | Optional |
| `ms-playwright.playwright` | Optional |
| `stylelint.vscode-stylelint` | Optional |
| `ms-vscode-remote.remote-containers` | Optional |
| `github.vscode-pull-request-github` | Optional |
| `usernamehw.errorlens` | Optional |
| `maxpowerengine.switch2datagrip` | Optional |
| `natqe.reload` | Optional |

### Full Stack overrides

```json
{
  "editor.tabSize": 2,
  "editor.insertSpaces": true,
  "prettier.requireConfig": false,
  "prettier.singleQuote": true,
  "prettier.semi": true,
  "prettier.printWidth": 100,
  "prettier.tabWidth": 2,
  "eslint.format.enable": false,
  "[typescript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
      "source.fixAll.eslint": "explicit",
      "source.sortImports": "explicit",
      "source.organizeImports": "never",
      "source.removeUnusedImports": "never"
    }
  },
  "[typescriptreact]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
      "source.fixAll.eslint": "explicit",
      "source.sortImports": "explicit",
      "source.organizeImports": "never",
      "source.removeUnusedImports": "never"
    }
  },
  "[javascript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
      "source.fixAll.eslint": "explicit",
      "source.sortImports": "explicit",
      "source.organizeImports": "never",
      "source.removeUnusedImports": "never"
    }
  },
  "[html]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true,
    "editor.quickSuggestions": {
      "strings": "on"
    }
  },
  "[scss]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true
  },
  "[css]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true
  },
  "[tailwindcss]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true
  },
  "prettier.documentSelectors": [
    "**/*.css"
  ],
  "tailwindCSS.validate": true,
  "tailwindCSS.lint.invalidApply": "error",
  "scss.lint.unknownAtRules": "ignore",
  "renameAngularComponent.showWhatsNewPopup": false,
  "renameAngularComponent.debugLog": false,
  "renameAngularComponent.useLocalDirectPaths": false,
  "renameAngularComponent.followAngular20FolderAndSelectorNamingConvention": false,
  "autoBarrel.files.disableRecursiveBarrelling": false,
  "autoBarrel.files.maxSearchRecursionDepth": 3,
  "autoBarrel.files.supportsHiddenFiles": false,
  "autoBarrel.files.preserveGitignoreSettings": true,
  "autoBarrel.files.detectExportsInFiles": true,
  "autoBarrel.files.useNamedExports": true,
  "autoBarrel.formatting.useSingleQuotes": true,
  "autoBarrel.formatting.sortExports": "alphabetical",
  "[prisma]": {
    "editor.defaultFormatter": "Prisma.prisma",
    "editor.formatOnSave": true
  },
  "search.exclude": {
    "**/dist": true,
    "**/coverage": true,
    "**/.nx": true,
    "**/.angular": true
  },
  "files.watcherExclude": {
    "**/dist/**": true,
    "**/coverage/**": true,
    "**/.nx/**": true,
    "**/.angular/**": true
  },
  "files.associations": {
    "*.css": "tailwindcss",
    "azure-pipelines.yml": "azure-pipelines",
    "azure-pipelines.yaml": "azure-pipelines",
    "**/.azure-pipelines/**/*.yml": "azure-pipelines",
    "**/.azure-pipelines/**/*.yaml": "azure-pipelines",
    ".env": "dotenv",
    ".env.*": "dotenv",
    "*.env": "dotenv"
  },
  "yaml.format.enable": false,
  "[yaml]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true
  },
  "[azure-pipelines]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true
  },
  "[sql]": {
    "editor.formatOnSave": false
  },
  "[dockerfile]": {
    "editor.formatOnSave": false
  },
  "gitlens.currentLine.enabled": false,
  "gitlens.codeLens.enabled": false,
  "gitlens.statusBar.enabled": true,
  "github.copilot.enable": {
    "*": true,
    "plaintext": false,
    "markdown": false,
    "scminput": false,
    "dotenv": false
  },
  "chat.useAgentSkills": true,
  "chat.useAgentsMdFile": true,
  "chat.useClaudeMdFile": true,
  "chat.useCustomizationsInParentRepositories": true,
  "github.copilot.chat.cli.customAgents.enabled": true,
  "chatgpt.openOnStartup": false,
  "chatgpt.composerEnterBehavior": "cmdAlways",
  "chatgpt.commentCodeLensEnabled": false,
  "[dotenv]": {
    "editor.formatOnSave": false,
    "editor.formatOnPaste": false,
    "editor.quickSuggestions": false,
    "editor.inlineSuggest.enabled": false,
    "editor.wordWrap": "off",
    "files.trimTrailingWhitespace": false
  },
  "chat.fontSize": 14,
  "chat.editor.fontSize": 13,
  "chat.editor.wordWrap": "on",
  "chat.checkpoints.enabled": true,
  "chat.checkpoints.showFileChanges": true,
  "chat.editing.autoAcceptDelay": 0,
  "chat.editing.confirmEditRequestRemoval": true,
  "chat.editing.confirmEditRequestRetry": true,
  "claudeCode.preferredLocation": "sidebar",
  "claudeCode.initialPermissionMode": "default",
  "claudeCode.allowDangerouslySkipPermissions": false,
  "claudeCode.useTerminal": false,
  "claudeCode.useCtrlEnterToSend": true,
  "claudeCode.attachOpenFile": false,
  "claudeCode.autosave": false,
  "claudeCode.continueAfterReload": false,
  "claudeCode.respectGitIgnore": true,
  "chatgpt.followUpQueueMode": "queue",
  "chatgpt.reviewDelivery": "inline",
  "fileutils.inputBox.pathType": "root",
  "fileutils.menus.context.explorer": [
    "moveFile",
    "duplicateFile",
    "copyFileName"
  ],
  "fileutils.menus.context.editor": [],
  "fileutils.menus.context.editorTitle": [
    "moveFile",
    "duplicateFile",
    "copyFileName"
  ],
  "workbench.colorCustomizations": {
    "titleBar.activeBackground": "#452568",
    "titleBar.activeForeground": "#FFFFFF",
    "activityBarBadge.background": "#9B6DDA"
  }
}
```

## AI

Apply Full Stack overrides before these overrides.

| Extension ID | Selection |
| --- | --- |
| `esbenp.prettier-vscode` | Recommended |
| `editorconfig.editorconfig` | Recommended |
| `pkief.material-icon-theme` | Recommended |
| `yzhang.markdown-all-in-one` | Recommended |
| `davidanson.vscode-markdownlint` | Recommended |
| `openai.chatgpt` | Recommended |
| `anthropic.claude-code` | Recommended |
| `omarbanat.goodprompts` | Recommended |
| `eamodio.gitlens` | Recommended |
| `dbaeumer.vscode-eslint` | Recommended |
| `angular.ng-template` | Recommended |
| `nrwl.angular-console` | Recommended |
| `prisma.prisma` | Recommended |
| `mikestead.dotenv` | Recommended |
| `redhat.vscode-yaml` | Recommended |
| `bradlc.vscode-tailwindcss` | Recommended |
| `imgildev.vscode-auto-barrel` | Recommended |
| `tomwhite007.rename-angular-component` | Recommended |
| `ms-vscode.vscode-chat-customizations-evaluations` | Optional |
| `ms-windows-ai-studio.windows-ai-studio` | Optional |
| `orta.vscode-jest` | Optional |
| `ms-playwright.playwright` | Optional |
| `ms-ossdata.vscode-pgsql` | Optional |
| `natqe.reload` | Optional |
| `sleistner.vscode-fileutils` | Optional |

### AI overrides

```json
{
  "workbench.colorCustomizations": {
    "titleBar.activeBackground": "#163A63",
    "activityBarBadge.background": "#2563EB"
  },
  "github.copilot.enable": {
    "*": false
  },
  "[markdown]": {
    "editor.quickSuggestions": {
      "other": "off",
      "comments": "off",
      "strings": "off"
    }
  },
  "files.associations": {
    "azure-pipelines.yml": "yaml",
    "azure-pipelines.yaml": "yaml",
    "**/.azure-pipelines/**/*.yml": "yaml",
    "**/.azure-pipelines/**/*.yaml": "yaml"
  }
}
```

## Operations

| Extension ID | Selection |
| --- | --- |
| `esbenp.prettier-vscode` | Recommended |
| `editorconfig.editorconfig` | Recommended |
| `pkief.material-icon-theme` | Recommended |
| `yzhang.markdown-all-in-one` | Recommended |
| `davidanson.vscode-markdownlint` | Recommended |
| `eamodio.gitlens` | Recommended |
| `redhat.vscode-yaml` | Recommended |
| `ms-azure-devops.azure-pipelines` | Recommended |
| `ms-azuretools.vscode-containers` | Recommended |
| `mikestead.dotenv` | Recommended |
| `ms-ossdata.vscode-pgsql` | Recommended |
| `ms-vscode-remote.remote-ssh` | Optional |
| `ms-vscode-remote.remote-ssh-edit` | Optional |
| `ms-vscode.remote-explorer` | Optional |
| `ms-vscode-remote.remote-containers` | Optional |
| `openai.chatgpt` | Optional |
| `anthropic.claude-code` | Optional |
| `foxundermoon.shell-format` | Optional |
| `maxpowerengine.switch2datagrip` | Optional |
| `natqe.reload` | Optional |

### Operations overrides

```json
{
  "files.associations": {
    "azure-pipelines.yml": "azure-pipelines",
    "azure-pipelines.yaml": "azure-pipelines",
    "**/.azure-pipelines/**/*.yml": "azure-pipelines",
    "**/.azure-pipelines/**/*.yaml": "azure-pipelines",
    ".env": "dotenv",
    ".env.*": "dotenv",
    "*.env": "dotenv"
  },
  "yaml.format.enable": false,
  "[yaml]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true
  },
  "[azure-pipelines]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true
  },
  "[sql]": {
    "editor.formatOnSave": false
  },
  "[dockerfile]": {
    "editor.formatOnSave": false
  },
  "[dotenv]": {
    "editor.formatOnSave": false,
    "editor.formatOnPaste": false,
    "editor.quickSuggestions": false,
    "editor.inlineSuggest.enabled": false,
    "editor.wordWrap": "off",
    "files.trimTrailingWhitespace": false
  },
  "gitlens.currentLine.enabled": false,
  "gitlens.codeLens.enabled": false,
  "gitlens.statusBar.enabled": true,
  "github.copilot.enable": {
    "*": false
  },
  "workbench.colorCustomizations": {
    "titleBar.activeBackground": "#174B3A",
    "titleBar.activeForeground": "#FFFFFF",
    "activityBarBadge.background": "#16805D"
  }
}
```

## Import keybindings

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
