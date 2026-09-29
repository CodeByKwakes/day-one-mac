[← Reference library](README.md) · [Manual handbook](../manual/README.md)

# Applications and formulae catalogue

**Purpose:** understand what each registered package does, when it is selected,
who owns installation and what still needs configuration. This is not an
“install everything” list. It describes this repository's current selection rules,
not the availability or pricing of every upstream product.

## Selection and ownership

- **Always** below means the required baseline after selecting a hosting track
  and language stack, not every Mac in existence.
- Hosting tracks: `1` GitHub, `2` Azure DevOps, `3` both. Language stacks: `node`,
  `python`, `both`.
- The `core` preset omits Raycast, Warp, VS Code and the Nerd Font. Other presets
  include that productivity group. Selecting another primary editor changes
  integration choices; it does not remove VS Code from that group's catalogue.
- 1Password and its CLI are required only for `1password` authentication, not
  `keychain`, `external` or `https`.
- Required formulae and selected required apps are supplied at the Installation
  Centre after Phase 2. Phase 4 verifies them; later phases configure them.
- Optional/advanced modules install only selected payloads. Sign-in, trust,
  shell activation, profile import and backups remain separate manual actions.

A Homebrew **formula** usually supplies a command-line package. A **cask** can
supply a desktop app, font or CLI—`1password-cli` and `codex` are casks here.
Use `brew info --formula TOKEN` or `brew info --cask TOKEN` to inspect the intended
package before choosing installation. Those lookups may access Homebrew's network.

For apps, keep a valid existing Homebrew, Company Portal, App Store or trusted
manual installation. Do not install a duplicate merely because `brew list` does
not know about it. Update through the actual owner. `check-only` reports missing
apps; an explicit Homebrew policy permits installation of missing selected apps.
`--yes` alone does not choose an owner.

## Registered applications, CLI casks and font

The ID is used by `day-one-mac applications --id ID`. That command checks
installation and records local provenance/state; it is not a read-only filesystem
query. It does not prove successful login or application configuration.

| ID | Name and purpose | Homebrew cask | Selection / phase | Manual setup and verification |
|---|---|---|---|---|
| `1password` | 1Password — account secrets and vault-owned SSH keys | `1password` | `1password` auth / 03 | Unlock correct account, establish recovery, enable agent; [walkthrough](../manual/1password.md) |
| `1password-cli` | 1Password CLI — authorised vault access from Terminal | `1password-cli` | `1password` auth / 03 | Enable integration; `op --version`, then approved account access; [walkthrough](../manual/1password.md) |
| `jetbrains-mono-nerd-font` | JetBrains Mono Nerd Font — coding font with prompt glyphs | `font-jetbrains-mono-nerd-font` | Non-core productivity / 04 | Select font in terminal/editor; inspect glyphs; [font check](../10-app-guides/README.md#check-the-required-font) |
| `raycast` | Raycast — launcher, capture and chosen workflow shortcuts | `raycast` | Non-core productivity / 04 | Choose shortcuts/permissions, test launch; [Raycast](../10-app-guides/RAYCAST.md) |
| `visual-studio-code` | Visual Studio Code — editor, profiles and extensions | `visual-studio-code` | Non-core productivity / 04, configuration 07 | Check `code --version` after CLI integration; select profile; [VS Code](../10-app-guides/VSCODE.md) |
| `warp` | Warp — terminal and optional shared workflows | `warp` | Non-core productivity / 04 | Open shell, check prompt/font, review account/import; [Warp](../10-app-guides/WARP.md) |
| `orbstack` | OrbStack — local container engine | `orbstack` | Optional / 09 | Launch, review resources/startup and `docker context show`; [databases](../02-optional/09-databases.md) |
| `dbeaver-community` | DBeaver Community — database connection/query GUI | `dbeaver-community` | Optional / 09 | Open app, connect to intended local test DB; [databases](../02-optional/09-databases.md) |
| `claude-code` | Claude Code — terminal AI coding client | `claude-code` | Optional / 10 | `claude --version`, chosen account and workspace permissions; [AI clients](../02-optional/10-ai-agents.md) |
| `codex` | Codex CLI — terminal AI coding client, not the desktop app | `codex` | Optional / 10 | `codex --version`, chosen account and workspace permissions; [AI clients](../02-optional/10-ai-agents.md) |
| `copilot-app` | GitHub Copilot app — graphical AI client | `github-copilot-app` | Optional / 10 | Open app, confirm account/entitlement and permissions; [AI clients](../02-optional/10-ai-agents.md) |
| `copilot-cli` | GitHub Copilot CLI — terminal AI client | `copilot-cli` | Optional / 10 | `copilot --version`, chosen account and permissions; [AI clients](../02-optional/10-ai-agents.md) |
| `obsidian` | Obsidian — local Markdown knowledge vaults | `obsidian` | Optional / Second Brain | Open intended vault and test capture/search/backup; [Second Brain](../manual/second-brain.md) |
| `purge` | Purge — optional cleanup application | `jithin-sabu/tap/purge` | Optional / 21 | Review exact candidates and recovery before any deletion; [maintenance](../03-advanced/21-audit-maintenance-and-rebuild.md) |

GUI apps should also be opened and tested: a valid bundle is not evidence of
permissions, connectivity or usability. Do not launch a cleanup operation as an
installation test. The catalogue records DBeaver's `dbeaver` and OrbStack's
`docker` command hints, but a missing optional launcher alone is not proof that
a GUI app is absent.

## Required and conditional formulae

Use `brew list --formula TOKEN` for Homebrew ownership/version evidence. The
command column names the executable, which may differ from the formula token.
Do not run commands against real projects solely as a presence check.

| Formula | Purpose | Selected when | Command | Configuration guide |
|---|---|---|---|---|
| `chezmoi` | Track and render portable dotfiles into the home directory | Always | `chezmoi` | [Learning path](../manual/chezmoi.md); review diffs before apply |
| `ghq` | Locate and clone repositories beneath reviewed roots | Only when opted in | `ghq` | [Developer folders](../manual/developer-folders.md); independent of hosting track and chezmoi |
| `git` | Version control for repositories and dotfiles | Always | `git` | [Phase 4](../01-required/04-core-tools-and-hosting.md); author identity and separate signing |
| `jq` | Read and transform JSON | Always | `jq` | [Foundation](../01-required/02-command-line-foundation.md); no account needed |
| `ripgrep` | Search file contents efficiently | Always | `rg` | [Core tools](../01-required/04-core-tools-and-hosting.md); no account needed |
| `starship` | Configurable cross-shell prompt | Always | `starship` | [Phase 5](../01-required/05-dotfiles-and-shell.md); shell init and font |
| `zsh` | Homebrew-managed interactive shell | Always | `zsh` | [Phase 5](../01-required/05-dotfiles-and-shell.md); inspect selected shell, not just PATH |
| `fnm` | Select and install Node.js versions | Node or both | `fnm` | [Phase 6](../01-required/06-language-toolchains.md); initialise shell, select Node |
| `pnpm` | Node project package manager | Node or both | `pnpm` | [Phase 6](../01-required/06-language-toolchains.md); respect project manager/version |
| `uv` | Manage Python versions, environments and dependencies | Python or both | `uv` | [Phase 6](../01-required/06-language-toolchains.md); use project environments |
| `gh` | GitHub account and repository CLI | GitHub or both | `gh` | [Phase 4](../01-required/04-core-tools-and-hosting.md); interactive login |
| `azure-cli` | Azure account and service CLI | Azure or both | `az` | [Phase 4](../01-required/04-core-tools-and-hosting.md); account/tenant and DevOps extension |

## Optional formulae

Every row below is opt-in via [Module 13](../02-optional/13-enhanced-cli-tools.md).
The purpose descriptions mirror `config/optional-formulae.tsv`. Installation
does not activate shell hooks, trust a certificate authority, accept an App Store
purchase or update a desired-state Brewfile. Use a reviewed Brewfile through
[Module 16](../03-advanced/16-brewfile-apps-and-editor.md) when deliberately adding
long-term ownership. The table is a supported selection catalogue, not all formulae
that Homebrew or Module 16 may accept.

| Group | Formula | Purpose | Command / manual follow-up |
|---|---|---|---|
| Containers | `dive` | Inspect Docker image layers and wasted space | `dive`; select a local development image |
| Containers | `lazydocker` | Terminal interface for Docker and Compose | `lazydocker`; verify context before mutating resources |
| Content | `ffmpeg` | Convert and inspect audio and video | `ffmpeg`, `ffprobe`; choose separate output files |
| Content | `gifsicle` | Create and optimise GIF files | `gifsicle`; preserve originals |
| Content | `imagemagick` | Convert and inspect raster images | `magick`; preserve originals |
| Development | `act` | Run GitHub Actions workflows locally | `act`; inspect workflow code, secrets and container context |
| Development | `actionlint` | Statically check GitHub Actions workflow files | `actionlint`; point at intended workflow |
| Development | `httpie` | Human-friendly HTTP client | `http`, `https`; avoid tokens in command history |
| Development | `mkcert` | Create locally trusted development certificates | `mkcert`; CA trust is a separate manual decision in [Module 19](../03-advanced/19-macos-gui-and-local-https.md) |
| Development | `shellcheck` | Static analysis for shell scripts | `shellcheck`; checks text without running the script |
| Development | `shfmt` | Format shell scripts consistently | `shfmt`; inspect a diff before write mode |
| Development | `watchman` | Watch files and trigger rebuilds | `watchman`; scope watches to the intended project |
| Development | `wget` | Download files from HTTP and FTP | `wget`; inspect source and destination |
| Development | `yq` | Query and edit YAML, JSON and XML | `yq`; inspect output before in-place edits |
| Git | `git-delta` | Readable Git diffs and syntax highlighting | `delta`; opt into pager settings manually |
| Git | `git-lfs` | Git support for large binary files | `git lfs`; review repository hooks/tracking rules |
| Git | `gitleaks` | Detect secrets in repositories | `gitleaks`; findings may themselves contain sensitive data |
| Git | `lazygit` | Terminal interface for Git | `lazygit`; check repository/branch before actions |
| Navigation | `bat` | Syntax-highlighted file viewer | `bat`; shell aliases are optional |
| Navigation | `eza` | Modern replacement for ls | `eza`; shell aliases are optional |
| Navigation | `fd` | Fast file finder | `fd`; choose search root |
| Navigation | `fzf` | Interactive fuzzy finder | `fzf`; shell keybindings/completion require opt-in |
| Navigation | `tree` | Display directory trees | `tree`; avoid publishing private directory inventories |
| Navigation | `zoxide` | Directory jumper learned from shell history | `zoxide`; review shell init before activation |
| Shell | `direnv` | Load per-project environment variables | `direnv`; read each `.envrc` before allowing execution |
| Shell | `zsh-autosuggestions` | Suggest commands from shell history | Shell plugin, no standalone command; source only after review |
| Shell | `zsh-completions` | Additional Zsh completions | Shell plugin; configure completion paths/order deliberately |
| Shell | `zsh-syntax-highlighting` | Highlight valid and invalid shell commands | Shell plugin; review shell load order |
| System | `btop` | Interactive process and resource monitor | `btop`; inspect rather than terminate processes as a test |
| System | `duf` | Readable filesystem usage | `duf`; inspect capacity |
| System | `dust` | Readable directory size analysis | `dust`; scope scans to intended directories |
| System | `hyperfine` | Command-line benchmarking | `hyperfine`; benchmarked commands really execute repeatedly |
| System | `mas` | Inventory and manage Mac App Store applications | `mas`; account, licensing and purchases remain manual |
| System | `tlrc` | Maintained tldr client for concise command examples | `tldr`; read examples before running them |
| System | `watch` | Repeat a command and display changes | `watch`; repeated commands can mutate data |

For a harmless install check, prefer `brew list --formula TOKEN` and
`command -v COMMAND` (replace both placeholders). Shell plugins have no executable to find.
Then use the tool's help in a test context; command presence does not prove shell
activation or correct configuration. [Module 17](../03-advanced/17-shell-and-package-automation.md)
covers reviewed helper activation, not automatic trust of every shell plugin.

## Related tools with different owners

| Tool or payload | Owner and boundary |
|---|---|
| Xcode Command Line Tools | Apple/macOS installation in Phase 2; not a Homebrew formula |
| Homebrew | Package manager bootstrap in Phase 2; casks/formulae are its separate payloads |
| Node.js and npm | Node installed through `fnm` in Phase 6; npm comes with Node, not a second global installation |
| Python | Managed through `uv` for the selected stack; do not replace macOS's system Python |
| Azure DevOps CLI extension | Installed through `az extension`, not a separate brew formula |
| Git Credential Manager | Optional/manual Azure HTTPS credential route; `git-credential-manager` cask is not a registered required application |
| Notion | Cloud account/workspace; browser/manual approved app route, not an automatically installed catalogue cask; [setup](../manual/second-brain.md) |
| SSH, Keychain, FileVault | macOS facilities; use Apple's SSH tools for Keychain integration; [security](../manual/security.md) |
| Database images and OmniRoute | Container payloads with separate versions/digests, volumes and startup policy; Modules 09/10A, not brew formulae |
| VS Code / Raycast extensions | Owned by the app/profile and its extension system; review permissions separately |
| MCP servers and AI subscriptions | Selected endpoint/package/account owners; installation does not grant trust or pay for access |
| Contributor dependencies | Repository `package.json`/lockfile; not required for end-user setup or offline documentation |

## Maintenance contract

Sources of truth: `config/applications.tsv`,
`scripts/lib/application-ownership.sh` (preset/auth filtering),
`scripts/setup.sh`'s `required_formulae`, and `config/optional-formulae.tsv`.
Catalogue fixtures check registered app IDs/casks, the required formula union,
and optional formula descriptions. Update this guide and its selection wording
when changing those sources; presence coverage alone cannot test prose semantics.

Do not automatically remove unlisted installed software: users and organisations
may own unrelated tools. Removing a package, deleting its data, revoking its account
and removing its dotfile configuration are separate decisions.
