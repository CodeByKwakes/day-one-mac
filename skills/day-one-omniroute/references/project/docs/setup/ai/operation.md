# Operate and maintain the setup assistant

Use a private workspace to keep guides, skills, client roles and session notes
together. Export never changes global client settings or starts an AI session.

For a smaller installation, use the [portable skill](../manual/ai/day-one-skills.md).
The single `day-one-mac` skill includes all workflows. An installed skill can
start immediately; the workspace export below is an optional alternative.

## Prepare a workspace

Prerequisites: a working client from [bootstrap](bootstrap.md). The optional
export tool also requires Node.js 22+ and a Day One Mac runtime containing
`assistant`; check `day-one-mac assistant --help`. Older published releases may
not contain it. See [runtime availability](../../shared/tools/runtime.md).

1. Preview the export:

   ```bash
   day-one-mac assistant --plan
   ```

   Expected result: an explanation of the exported files, with no writes.

2. Create a parent directory for private setup sessions:

   ```bash
   mkdir -p "$HOME/Developer/Setup"
   ```

   Expected result: a directory owned by your account. Choose another private
   location if your organisation specifies one.

3. Export to a new directory:

   ```bash
   SETUP_WORKSPACE="$HOME/Developer/Setup/day-one-$(date +%Y%m%d-%H%M%S)"
   day-one-mac assistant --export "$SETUP_WORKSPACE"
   ```

   Expected result: a private workspace with `START.md`, `AGENTS.md`, seven skills,
   client roles, guides and an integrity manifest. Existing destinations are refused.

4. Verify the export:

   ```bash
   day-one-mac assistant --check "$SETUP_WORKSPACE"
   ```

   Expected result: `Assistant files verified`. This proves file consistency,
   not publisher authenticity, account access or machine readiness.

5. Open the directory using the selected [client guide](README.md).

   Expected result: the client can read `START.md` and discover its role definitions.
   Claude's `.claude/skills` links to `.agents/skills`; skill contents have one copy.

Without the exporter, download and review a versioned source archive, then use
[manual skill and agent preparation](../manual/ai/day-one-skills.md). This does
not install or invoke Day One Mac scripts. It requires no permanent Git checkout.

## Plan, approve and execute

1. Start with this prompt:

   ```text
   Use day-one-mac to inspect my Mac and propose setup for the capabilities
   in my worksheet. Do not make changes. Offer direct access, existing
   OmniRoute, local OmniRoute or gateway setup later. Include exact commands,
   affected paths, prerequisites, human steps and recovery.
   ```

   Expected result: a bounded plan based on the observed machine and your choices.

2. Approve the desired scope in the client, then use the operator role.

   Expected result: only the approved capabilities are changed. Normal client
   confirmations remain active. A changed destructive scope needs a new decision.

3. Ask the verifier to review the results using `day-one-check`.

   Expected result: installed, configured, verified and unresolved outcomes are
   distinguishable. Read-only roles request fresh probe output when they cannot run it.

## Record and resume

With your approval, the assistant records notes in `session/progress.md`:
selected capability, owner, intended change, command/check, observed version,
result, remaining human step and recovery location. Keep credentials out of notes.
The integrity checker permits private files under `session/` but does not inspect them.

Resume by opening the same workspace and asking the assistant to read the notes
and recheck the machine. Interrupted work remains incomplete until verified.
Do not rerun installations solely because a session lost its chat history.

## Update, remove and extend

Export a new directory after a reviewed runtime update. Verify it before use,
compare changed skills/roles, and copy only the private notes you need. Keep
customised old files for comparison; the exporter never overwrites them.

To remove a workspace, close sessions, back up needed notes, and move that exact
directory to Trash in Finder. Global clients, installed developer tools and
runtime state remain separate. See [component lifecycle](../manual/lifecycle.md).

Add project support through [adding capabilities](../../shared/reference/adding-capabilities.md).
Optional MCP connections, logging and scheduling are separate opt-ins. Redact
logs before sharing; do not put credentials into prompts or unattended jobs.
