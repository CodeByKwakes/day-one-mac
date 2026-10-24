# Configure the shell and choose a file owner

Choose who owns your settings before editing them. You need native Homebrew and
a recoverable copy of existing shell files. This manual route has no required
Day One Mac phase or generated state.

## 1. Choose configuration ownership

| Choice | What to do | Expected result |
|---|---|---|
| User-owned | Edit your home files directly and include them in a tested backup | No chezmoi dependency |
| Chezmoi local-only | Follow [chezmoi setup](chezmoi.md), then protect the local source in an encrypted backup | Source and target are distinct and recoverable |
| Chezmoi private Git | Follow [chezmoi setup](chezmoi.md) and verify the private remote | Only reviewed, non-secret configuration is versioned |

Do not manage a file with two independent sync tools. An application's Settings
Sync and chezmoi can both overwrite settings; choose the owner deliberately.

## 2. Select the shell

Keep a working Zsh, use Apple's `/bin/zsh`, or deliberately install Homebrew Zsh
with `brew install zsh`. Installing a binary does not change the login shell.
Follow the [Zsh guide](zsh.md) to configure startup and application shell paths.

Expected result: a new terminal uses the executable you selected. On managed
Macs, login-shell changes need the approved process; `/bin/zsh` is already present.

## 3. Select the prompt

Keep the existing prompt, or install Starship with `brew install starship` and
add its guarded initialisation once in `.zshrc` as the Zsh guide shows.

Expected result: one prompt initialiser runs, without duplicated output or delay.

## 4. Verify before closing the working terminal

Open a new terminal and check the selected tool paths. Keep the original terminal
open until the new one works. Use [Zsh troubleshooting](zsh.md) for startup,
completion, history and Warp differences.

Expected result: login and interactive sessions find the same intended tools.
If startup fails, use `/bin/zsh -f` and restore the last reviewed file change.

Next: [language toolchains](../languages.md). Optional [aliases](aliases.md)
should be added only after the base shell works.
