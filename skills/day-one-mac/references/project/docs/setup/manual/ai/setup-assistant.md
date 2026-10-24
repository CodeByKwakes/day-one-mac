# Prepare optional AI assistance before setup

Choose AI assistance before starting the base setup if you want help throughout
it. You need one approved client. Homebrew, Node, an editor and MCP servers are
not prerequisites for the native CLI route below. Keep additional clients and
integrations for [later client setup](clients.md).

## Objective and prerequisites

Read the [shared prerequisites](../../../shared/prerequisites.md) and confirm
your organisation permits the selected client, account and data use. Check
network access and the provider's current account, region, usage and billing
requirements. Installation does not establish an entitlement to use a model.

If an existing Mac still needs backup or a planned reset, use browser guidance
on that Mac or another device. Install local tooling after the approved starting
boundary is established. AI cannot verify a recovery key or accept a licence
for you. Never include credentials or private inventories in a shared prompt.

The procedures assume native Apple-silicon macOS supported by this project.
They use macOS Terminal and built-in tools. A **CLI** is a program used from a
terminal; a **skill** is a reusable instruction file, not a permission grant.

## 1. Choose the level of assistance

| Choice | Client requirement | Who runs setup commands | Start here |
|---|---|---|---|
| No AI | None | You | Return to the [manual sequence](../README.md) |
| Guidance only | An approved browser, desktop or CLI client | You, after reviewing each command | Reuse the client; continue at Step 4 |
| Assisted execution | An approved local client with command tools | The client, within each approved scope | Reuse or install one CLI in Step 2 |

Expected result: a recorded mode and one selected client. Guidance remains
available if local execution or account access is unavailable. Never choose an
unrestricted execution mode merely to make setup prompts disappear.

## 2. Reuse a client or review one native installer

1. Check the selected command, one at a time:

   ```bash
   command -v codex
   # Or, when Claude Code is selected:
   command -v claude
   ```

   Expected result: an executable path. Also inspect `~/.local/bin` if the
   command is absent from PATH. Reuse an approved existing installation; retain
   its vendor, Homebrew or company update owner. Skip installation when found.

2. If missing, choose one official installer in this terminal:

   ```bash
   printf 'Install which missing client (codex or claude)? '
   IFS= read -r setup_client
   case "$setup_client" in
     codex) installer_url=https://chatgpt.com/codex/install.sh; installer_shell=/bin/sh ;;
     claude) installer_url=https://claude.ai/install.sh; installer_shell=/bin/bash ;;
     *) printf 'No client selected\n' >&2; return 1 2>/dev/null || exit 1 ;;
   esac
   umask 077
   installer_dir="$(mktemp -d "$HOME/AI-installer-review.XXXXXX")"
   ```

   Expected result: a private review directory and one selected URL. Compare
   that URL with the current [Codex installation guide](https://learn.chatgpt.com/docs/cli)
   or [Claude Code installation guide](https://code.claude.com/docs/en/setup).
   These are vendor installers; they maintain their own files and update routes.

3. Download the selected installer without running it:

   ```bash
   curl --proto '=https' --proto-redir '=https' --tlsv1.2 -fL \
     --connect-timeout 15 --max-time 180 "$installer_url" \
     -o "$installer_dir/install.sh"
   ```

   Expected result: exit status 0 and a non-empty script. Stop on a network
   error; a partial download is not usable.

4. Inspect syntax and the downloaded content:

   ```bash
   test -s "$installer_dir/install.sh" && "$installer_shell" -n "$installer_dir/install.sh"
   shasum -a 256 "$installer_dir/install.sh"
   LESSSECURE=1 LESS='' LESSOPEN='' LESSCLOSE='' /usr/bin/less "$installer_dir/install.sh"
   ```

   Expected result: no syntax error and readable installer content. Press `q`
   to leave the viewer. The hash identifies the file; it does not authenticate
   the publisher. Review any secondary downloads against the provider's guide.

5. Only after accepting that install, run the reviewed script:

   ```bash
   /usr/bin/env -u BASH_ENV -u ENV "$installer_shell" "$installer_dir/install.sh"
   ```

   Expected result: the installer reports its installation location and any
   required PATH changes. Stop on failure and preserve its output locally.
   Do not retry through a second package manager to conceal a failed install.

## 3. Verify the executable and sign in

1. Open a new terminal and check the selected version:

   ```bash
   # Add the standard native location for this terminal only if needed.
   export PATH="$HOME/.local/bin:$PATH"
   codex --version
   # Or:
   claude --version
   ```

   Expected result: the selected CLI prints its version. Run only your selected
   command. Later, merge the needed PATH entry through your chosen
   [shell configuration owner](../shell/README.md).

2. Start the selected client and complete its supported sign-in flow:

   ```bash
   codex
   # Or:
   claude
   ```

   Expected result: the intended account can send a harmless prompt. Select
   subscription or API billing deliberately. Complete browser approval yourself;
   keep tokens out of shell configuration, prompts and documentation.

3. Ask for a short text response without tools.

   Expected result: the chosen account/model responds. A version check alone
   cannot prove authentication, quota, billing or command-tool access.

## 4. Prepare a private setup task

1. Follow [skill installation](day-one-skills.md) in a new private setup folder.
   Install the single `day-one-mac` skill for your selected client. Its six
   workflows and supporting guides are included; native agent roles are optional.

   Expected result: `.agents/skills/day-one-mac/SKILL.md` and its bundled
   references exist. A Claude-only install uses `.claude/skills/day-one-mac`.
   Installing for Claude alongside Codex or Copilot links Claude to the shared copy.

2. Open the setup folder in your client and ask it to read the installed skill.

   Expected result: the client can explain its setup and checking workflows and
   open the bundled guides. This installation does not require root-level
   `START.md` or `AGENTS.md`. The optional [workspace export](../../ai/operation.md)
   supplies those files and configured agent directories if you prefer that layout.

3. In a browser-only session, attach the relevant bundled guide and workflow,
   then request guidance without execution. Do not attach private progress notes
   by default.

   Expected result: the client can cite the supplied procedure and explain its
   prerequisites. If the documents are unavailable, stop instead of guessing.

## 5. Verify the permitted tools

1. Open the task folder in the selected local client, or attach its instruction
   files and the relevant guide to your browser client.

   Expected result: the client identifies the route and assistance mode. If it
   cannot read the guides, provide the relevant files; do not let it invent steps.

2. Send this first request:

   ```text
   Read the setup instructions and skill. Summarize the chosen route and mode.
   Propose the next setup step and its verification. Do not change anything.
   ```

   Expected result: a plan with prerequisites, commands, effects and recovery.

3. For execution mode only, approve this harmless command test:

   ```text
   Run only pwd, uname -m and sw_vers. Show their results and stop.
   Do not read any other files or change configuration.
   ```

   Expected result: the task directory, `arm64` and the macOS version. Keep
   client permissions limited to the current task. If tools are unavailable,
   use guidance mode and run reviewed commands yourself.

4. Continue with the [manual base sequence](../README.md#follow-the-base-setup).
   Request approval for the next concrete set of changes after reviewing it.

   Expected result: each phase ends with its own checks. No-AI and guidance
   routes remain usable when a provider is unavailable. Continue with the
   [AI operation cycle](../../ai/operation.md) if you chose approved local execution.

## Troubleshooting and rollback

| Symptom | Action | Verification |
|---|---|---|
| Command missing | Check the installer path and a fresh terminal's PATH | Selected `--version` succeeds |
| Sign-in or quota fails | Resolve the intended account with its provider, or use no AI | A harmless prompt succeeds or AI is intentionally skipped |
| Guide/skill not loaded | Attach the files or request explicit reads | Client names the route and boundaries correctly |
| Install failed | Preserve output and inspect vendor recovery instructions | One working installation owner remains |
| Client proposes broad access | Decline that request; use a smaller action or guidance | Only the approved tools and scope are used |

To stop using assistance, close the session and continue the manual route.
Preserve the task notes until setup is accepted. Remove a client only through
its original installer or company policy; deleting this task folder does not
remove account sessions, client history or installed binaries. Revoke account
access through the provider when required.

## Verification scope and later enhancements

Repository checks validate command syntax, guarded examples and simulated
failure paths. They do not establish live provider access or a real new-Mac
installation. Complete the local sign-in/tool test yourself.

After the base works, add [project skills and agents](instructions-agents-skills.md)
or [MCP connections](mcp.md) for a specific task. Keep a private record of
approved changes and observed checks. A CI job can validate documentation and
packaging; it cannot attest to this Mac's permissions or recovery readiness.
