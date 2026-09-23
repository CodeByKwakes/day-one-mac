[← Start here](../START-HERE.md) · [Day One Mac home](../README.md)

# Plain-English glossary

These definitions apply throughout Day One Mac. A term is included because it
describes an action or a file the user may need to review.

| Term | Plain-English meaning |
|---|---|
| **Apply** | Make the reviewed configuration changes active. With chezmoi, `chezmoi apply` copies the generated settings to their normal locations. |
| **AI gateway** | A service between an AI client and one or more model providers. OmniRoute is an optional local gateway; it routes model requests but does not control the client's file or Terminal permissions. |
| **Authentication** | Proving to a service that you are the account owner, usually through a browser, device code, or SSH key. |
| **Authentication mode** | How this Mac proves its identity to GitHub or Azure DevOps: `1password` (the 1Password SSH agent, the default), `keychain` (a passphrase-protected key file held by the macOS Keychain), `external` (an agent you already run), or `https` (no SSH key at all). Shown by `day-one-mac --status`. |
| **AUTO_CD** | An optional zsh setting that changes directory when you type a bare path, so `~` goes home instead of failing. Offered in Module 13; off by default on macOS. |
| **Brewfile** | A text list of software that Homebrew can reinstall. It is desired state, not a backup of application data. |
| **Cask** | Homebrew's package type for a macOS application or font, such as VS Code or Raycast. |
| **External application** | A valid application or command that Homebrew does not own. It may have come from Company Portal, the Mac App Store, a company administrator, or a manual installer. Day One Mac preserves it. |
| **chezmoi source** | The private working folder containing the master copies or templates of settings managed by chezmoi. |
| **chezmoi target** | The normal file produced from the source, such as `~/.zshrc`. |
| **CLI** | Command-line interface: a tool used by typing commands in Terminal rather than clicking an app window. |
| **Commit** | A named, permanent Git snapshot of reviewed changes. |
| **Container** | An isolated runtime for a service such as PostgreSQL. It is lighter than a full virtual machine. |
| **Certificate authority (CA)** | A trusted issuer of digital certificates. A local development CA lets browsers trust reviewed local HTTPS certificates. |
| **Diff** | A comparison that shows exactly what text will change. A line starting with `-` is removed; a line starting with `+` is added. |
| **Domain** | In the Second Brain, a subject area such as software development or content creation. It does not mean an internet domain. |
| **Dotfile / dotfiles** | A configuration file whose name begins with a dot, such as `~/.zshrc` or `~/.gitconfig`. macOS hides these in Finder by default. They hold your personal settings for tools like the shell and Git, which is why this project manages them with chezmoi. |
| **Dry run / preview** | Show intended actions without making the changes. |
| **Environment variable** | A named value inherited by commands, such as `PNPM_HOME`. It configures behavior without being typed into every command. |
| **APFS** | Apple File System: the current macOS disk format. Stage 0 requires an encrypted external APFS volume for an account-preserving cleanup archive. |
| **Fingerprint** | A saved checksum of the phase document, its version, and relevant choices. It tells the runner whether a completed phase needs review after a change. |
| **FileVault** | Apple's full-disk encryption. With it on, the contents of the disk are unreadable without your login password or recovery key, so a lost or stolen Mac does not expose your files. Phase 3 requires it. |
| **fnm** | Fast Node Manager: installs multiple Node.js versions under your account and switches between them per project, so no single Node release is baked into the system. |
| **Formula** | Homebrew's package type for a command-line tool or library. |
| **Gate** | A check that must pass before a phase can be marked complete. |
| **Gatekeeper** | The macOS feature that checks an application is from an identified developer and has not been tampered with before letting it run. Phase 8 verifies it is still enabled. |
| **ghq** | A command-line tool that stores cloned Git repositories in a predictable provider/owner/repository folder structure. |
| **Homebrew prefix** | Homebrew's installation root. Day One Mac requires the native Apple-silicon prefix `/opt/homebrew`. |
| **Idempotent** | Safe to run repeatedly: an existing correct item is kept instead of duplicated. |
| **Identity / SSH identity** | The public/private key pair an SSH agent can use to prove who you are. Day One Mac keeps its private part in 1Password. |
| **Image** | In Docker, the read-only package used to create a container. |
| **JSON / JSONC** | Structured text formats used for settings. JSONC is JSON that also allows comments. |
| **Lockfile** | A project file, such as `pnpm-lock.yaml`, that records exact dependency versions for repeatable installs. |
| **LTS** | Long-Term Support: a Node.js release intended to receive fixes for longer than short-lived releases. |
| **Manifest** | A machine-readable list of items a script installed or changed. Cleanup uses it to avoid guessing ownership. |
| **Preflight / audit** | A check performed before changes. In Stage 0 it means a read-only safety report; it does not copy, remove, or back up data. |
| **Provenance** | Evidence showing where an application came from and whether Day One Mac installed it. The application provenance report distinguishes Homebrew from external ownership. |
| **Safety report** | The required first Stage 0 step for Route A and Route B. It lists current applications, repositories, packages, containers, and configuration locations so backup risks can be reviewed. Older files call it a preflight audit. |
| **Stage 0** | The optional process used before Phase 1 when a Mac still has data or settings: create the safety report, test an encrypted backup, then choose Route A or Route B. |
| **Route A** | Erase the current accounts, applications, files, settings, and credentials using Apple's Erase All Content and Settings. The Day One script shows the handoff but does not perform the erase. |
| **Route B** | Keep the current macOS account and non-Homebrew applications while removing the known development setup after a no-change preview and backup gates. Unknown settings can remain. |
| **Dirty repository** | A Git repository containing local file changes that have not been committed. These changes may exist nowhere else. |
| **NO-REMOTE** | A repository report status meaning no `origin` URL is configured, so the local repository may have no server-side copy. |
| **MCP** | Model Context Protocol: a standard way for an AI client to connect to an approved external tool or data source. |
| **OAuth** | A browser-based permission flow that lets an app access an account without receiving the account password. |
| **Personal access token (PAT)** | A revocable GitHub credential used instead of an account password for HTTPS Git or API access. A fine-grained PAT can be limited to one owner, selected repositories, specific permissions, and an expiration date. |
| **Endpoint key** | A secret that lets a client call a gateway endpoint. An OmniRoute endpoint key is separate from the upstream provider credential. |
| **Port** | A numbered local network endpoint used by a service, such as PostgreSQL on 5432. |
| **PATH** | The ordered list of directories the shell searches when you type a command name. |
| **Process** | A running application or command. An application can start child processes, also called subprocesses. |
| **Nerd Font** | A normal programming font that has had extra icon characters added to it. Starship and many Terminal tools draw those icons; without a Nerd Font they appear as empty boxes. This project installs JetBrains Mono Nerd Font. |
| **pnpm** | A fast Node.js package manager. It stores one shared copy of each package on disk and links it into projects, so repeated installs use far less space than npm. |
| **Remote** | A Git repository stored on a service such as GitHub or Azure DevOps. `origin` is the conventional name for the primary remote. |
| **Rosetta** | Apple's translation layer that lets Intel software run on Apple-silicon Macs. Day One Mac requires native Apple-silicon (`arm64`) execution and refuses to run under Rosetta, because a translated Terminal installs the wrong Homebrew. |
| **Repository / repo** | A folder whose files and change history are tracked by Git. |
| **Scope** | The resources or permissions a credential or integration is allowed to use. Smaller scope is safer. |
| **Login shell** | The shell macOS starts for you, recorded per account and shown by `dscl . -read "/Users/$(id -un)" UserShell`. Phase 5 offers to change it from `/bin/zsh` to Homebrew's zsh; `chsh -s /bin/zsh` restores it. |
| **Shell** | The program that reads Terminal commands. macOS uses Zsh by default; Day One Mac installs Homebrew's zsh and can make it the login shell. |
| **Shim** | A small compatibility command that forwards an old command name to its replacement. |
| **SDK** | Software Development Kit: tools and libraries used to build software for a platform. |
| **Socket** | A special local connection file. The 1Password SSH agent socket lets SSH request a signature without copying out the private key. |
| **Starship** | The Terminal prompt used by this project. It replaces the default `%` prompt with one showing the current folder, Git branch, and language version. Configured in `~/.config/starship.toml`. |
| **Upstream branch** | The remote branch your local branch is linked to, set by `git push -u origin main`. Once set, plain `git push` and `git pull` know where to go, and Phase 8 can confirm your work reached the server. |
| **uv** | A fast Python package and version manager. It installs Python interpreters under your account and manages per-project dependencies, so the system Python is left alone. |
| **Symlink** | A symbolic link: a filesystem pointer that redirects one path to another file or folder. |
| **SSH agent** | A service that offers approved SSH identities to Git without exposing the private key file. |
| **SSH approval session** | A temporary 1Password permission joining one SSH key to a requesting application, terminal tab, or single request. Its scope and duration determine when another prompt appears. |
| **stdio** | Standard input/output: a local MCP transport in which an AI client starts and communicates with a command on the same Mac. |
| **Template / frontmatter** | A reusable note pattern; frontmatter is the structured property block at the top of a Markdown note. |
| **TCC / privacy database** | macOS's record of which apps may access protected resources such as files, camera, microphone, or automation. TCC stands for Transparency, Consent, and Control. |
| **TOML** | A structured text format commonly used for configuration, including chezmoi machine data. |
| **TSV** | Tab-separated values: a plain-text table whose columns are separated by tab characters. |
| **Vault** | An Obsidian knowledge-base folder containing notes, attachments, and Obsidian settings. |
| **Volume** | Persistent Docker data stored separately from the container, or a mounted macOS storage device depending on context. |

When a command or error still is unclear, copy the exact message and the phase
number. Do not hide or paraphrase the first failing line.
