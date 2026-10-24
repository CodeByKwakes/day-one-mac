# Check prerequisites

Use this checklist before either setup route. Complete only the tools and
accounts selected in the [decision worksheet](decisions.md).

## Platform and evidence

| Requirement | How to check | Expected result |
|---|---|---|
| Native Apple silicon | `uname -m` | `arm64`; use a terminal without Rosetta |
| macOS accepted by the runtime | `sw_vers -productVersion` | Major version 15-27; acceptance and testing evidence are distinguished below |
| Storage | System Settings, General, Storage | At least 30 GB free for the base; budget separately for Xcode, containers, models and projects |
| Account | Confirm with the owner or IT | Personal administrator, or managed standard daily account with approved elevation |
| Backup | Restore a sample file from another location | Readable, independent copy of the data you need |
| Network | Open the approved software and hosting services | Trusted connection; managed proxy, VPN and certificate requirements supplied by IT |
| Power | Connect the power adapter | Stable power during updates and downloads |

The platform guard, `src/core/platform.sh`, defines which versions the runtime
accepts. CI configuration includes macOS 15 and 26. Hardware and managed-device
validation require separate evidence for the actual device and OS build. Follow
[verification](verification.md) for the distinction between local checks and
physical-device acceptance. Intel, Rosetta execution, Windows and Linux are not
supported setup targets.

## Tool prerequisites by task

| Task | Required first | Check |
|---|---|---|
| Homebrew installation | Apple Command Line Tools and an approved native installation | `xcode-select -p`; `/opt/homebrew/bin/brew --prefix` |
| Base manual Node stack | Homebrew, fnm and pnpm | Follow [language setup](../setup/manual/languages.md) |
| Base manual Python stack | Homebrew and uv | Follow [language setup](../setup/manual/languages.md) |
| VS Code profile generation | A runtime exposing `vscode-profile`, Node.js 22 or newer | `day-one-mac --help`; `node --version`, on the assisted route only |
| Containers | One selected, running container engine | `docker info` and the intended Docker context |
| PostgreSQL client | A reachable server, database, permitted role and environment details | Complete the chosen [database guide](../setup/manual/databases/README.md) |
| AI client or MCP integration | Chosen client/account, access policy and required executable | Check that client's guide before installing servers |

A Python-only base does not automatically satisfy a later Node-based tool's
requirements. Install that prerequisite deliberately when choosing the optional
task. Full Xcode is optional; Command Line Tools suffice for the base.

## Accounts and managed devices

1. Confirm the selected hosting account and multi-factor authentication recovery.

   Expected result: you can recover access without relying solely on this Mac.

2. Obtain a repository clone URL you are authorised to read for each provider.

   Expected result: the URL contains no password or token. Private repository
   access can prove authentication; a public repository may work anonymously.

3. On managed devices, obtain IT approval for enrollment, software installation,
   elevation, certificates, recovery escrow and update deadlines.

   Expected result: each control has an owner and current non-secret evidence.
   Do not change a managed preference to make an example match.

## Offline and existing-Mac limits

The assisted runtime can be installed from an existing archive. That does not
supply all Homebrew downloads, application installers, language packages or
account access offline. A disconnected build needs a separately approved
software distribution plan.

For a populated Mac, the assisted route has an
[existing-Mac preparation procedure](../setup/assisted/existing-mac/README.md).
The manual route does not provide an equivalent broad account-preserving cleanup.
Use a tested backup and your approved reset/new-account process, then begin the
manual setup. This guide does not erase or format a disk.

## Troubleshooting

| Symptom | Next action |
|---|---|
| `uname -m` prints `x86_64` | Check native terminal execution; stop on Intel hardware |
| Downloads fail behind a managed network | Give IT the failing host, time and non-secret error; request the approved proxy/CA configuration |
| No approved elevation | Ask IT to provision the required tools; do not promote the daily account |
| Backup has never been restored | Test a sample restore before setup or cleanup |

Next: complete the [decision worksheet](decisions.md), then select your route.

## Optional AI prerequisite

If AI will help with the whole setup, prepare one client through the
[early AI checkpoint](../setup/manual/ai/setup-assistant.md) before the base.
Confirm device policy, account access and permitted tools. Browser guidance can
start before a planned reset; install local clients after that boundary. AI,
MCP and additional clients are not required for the normal manual or assisted
route.
