# Record setup decisions

Keep one private worksheet for the whole setup. Use it when a guide asks which
software, account or configuration owner to use. A choice here does not install
anything.

| Decision | Choices | Record |
|---|---|---|
| Setup route | Scripted (Assisted) / Manual | One route |
| Early AI assistance | None / guidance only / approved execution | One client, account and tool check before Phase 1; [AI checkpoint](../setup/manual/ai/setup-assistant.md) |
| Device ownership | Personal / managed | Owner and approval process |
| Software preset | Core / recommended productivity | Core omits VS Code, Warp, Raycast and the Nerd Font |
| Hosting | GitHub / Azure DevOps / both / self-managed | Providers and authorised repository URLs |
| Languages | Node / Python / both | Project version policy |
| Git identity | Author name and email | Approved identity, separate from login |
| Git authentication | 1Password SSH / Keychain-backed SSH / external agent / HTTPS | One owner per identity |
| HTTPS helper | GCM / approved existing helper | Helper and provider scope |
| Configuration owner | User-owned / chezmoi local-only / chezmoi private Git | Owner and recovery location |
| Shell | Keep existing Zsh / Apple Zsh / Homebrew Zsh | Executable path |
| Prompt | Keep existing prompt / Starship | One prompt owner |
| Developer layout | None / repository / purpose / existing | Root and optional ghq choice |
| Editor integration | VS Code / preserve another editor | Git editor/diff/merge ownership |
| Optional work | Databases, AI, MCP, profiles, Second Brain, other tools | Add only a capability needed by a project |

The assisted runner calls the hosting choices tracks 1 (GitHub), 2 (Azure),
3 (both) and 4 (self-managed). Hosting, authentication, languages and layout are
independent. Core still requires the chosen authentication and language checks.
1Password is required only when its authentication mode is selected.

Local-only chezmoi still has a source directory that needs an encrypted backup.
User-owned configuration does not require chezmoi. Private Git is a way to
protect reviewed non-secret configuration; it is not storage for credentials.

## Complete the worksheet

1. Record the choices and the responsible owner in private setup notes.

   Expected result: another session can resume without guessing the selection.

2. Compare software choices with the [catalogue](reference/software-catalogue.md).

   Expected result: optional tools are distinguishable from selected prerequisites.

3. Record the backup and recovery checks from [verification](verification.md).

   Expected result: the evidence describes a check you performed, not just an
   intended backup location. Never include recovery codes or tokens.

Next: [Assisted Setup](../setup/assisted/README.md) or
[Manual Setup](../setup/manual/README.md).
