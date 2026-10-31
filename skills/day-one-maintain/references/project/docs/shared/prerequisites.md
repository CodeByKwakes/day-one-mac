# Check prerequisites

Use this checklist before either setup route. Complete only the tools and
accounts selected in the [decision worksheet](decisions.md).

## Platform and evidence

| Requirement | How to check | Expected result |
|---|---|---|
| Native Apple silicon | `uname -m` | `arm64`; use a terminal without Rosetta |
| macOS guidance baseline | `sw_vers -productVersion` | macOS 15 or newer; use a vendor-supported, IT-approved build |
| Storage | System Settings, General, Storage | At least 30 GB free for the base; budget separately for Xcode, containers, models and projects |
| Account | Confirm with the owner or IT | Personal administrator, or managed standard daily account with approved elevation |
| Backup | Restore a sample file from another location | Readable, independent copy of the data you need |
| Network | Open the approved software and hosting services | Trusted connection; managed proxy, VPN and certificate requirements supplied by IT |
| Power | Connect the power adapter | Stable power during updates and downloads |

CI configuration includes macOS 15 and 26. The guides do not certify every
future OS or application combination. Hardware and managed-device
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
| VS Code profile generation | Reviewed bundled helper and Node.js 22.20 or newer | `node --version`; helper `--help` |
| Containers | One selected, running container engine | `docker info` and the intended Docker context |
| PostgreSQL client | A reachable server, database, permitted role and environment details | Complete the chosen [database guide](../setup/manual/databases/README.md) |
| AI client or MCP integration | Chosen client/account, access policy and required executable | Check that client's guide before installing servers |
| GitHub skill installation | Node.js 22.20 or newer, npm, working Git and an approved client | `node --version`; `npm --version`; `git --version`; [source selection](../setup/manual/ai/day-one-skills.md#choose-a-reviewed-source) |

A Python-only base does not automatically satisfy a later Node-based tool's
requirements. Install that prerequisite deliberately when choosing the optional
task. Full Xcode is optional; Command Line Tools suffice for the base.

## Capability-specific limits

The platform baseline above applies to the base journey. Check optional tasks
before selecting them; passing the base does not satisfy every application's floor.

| Capability | Additional requirement or boundary | Owning guide |
|---|---|---|
| Manual skill copy | Reviewed complete package and a client that discovers it; no Node or Git needed just to copy files | [Skill sources](../setup/manual/ai/day-one-skills.md#choose-a-reviewed-source) |
| Native plugins | The selected client's plugin commands and a reviewed artifact; verify discovery separately | [Plugin prerequisites](../setup/manual/ai/day-one-plugins.md#prerequisites-and-package-review) |
| Atticus voice pilot | Its reviewed source requires macOS 26+ and separate build/provider prerequisites | [Atticus](../setup/manual/apps/atticus.md#decide-whether-it-fits) |
| Developer shortcut launchers | Rebuild/import on the destination; inspected Add to Dock launchers require macOS 26.7 and reference local shortcuts | [Portable shortcut forms](../setup/manual/apps/macos-shortcuts.md#understand-launcher-apps-and-transferable-shortcuts) |
| Display workspace restore | Actual monitor topology, approved driver and private calibration | [Workspace setup](../setup/manual/apps/workspaces.md) |

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

Guides and skill snapshots can be copied from a reviewed archive. This does not
supply Homebrew downloads, application installers, language packages or
account access offline. A disconnected build needs a separately approved
software distribution plan.

For a populated Mac, inventory existing tools and test a backup before either
route. Keep working applications and their owners. Broad cleanup and account
reset are outside this project; neither route erases or formats a disk.

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
