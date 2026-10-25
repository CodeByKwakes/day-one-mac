# Operate and maintain the setup assistant

Install the [portable skill](../manual/ai/day-one-skills.md) in a private setup
folder after [preparing one AI client](bootstrap.md). The single `day-one-mac`
skill includes setup, checks, maintenance, recovery, OmniRoute and contribution.
No runtime command or workspace exporter is required.

## Prepare and verify

1. Follow the skill guide's GitHub or local installation steps.

   Expected result: the selected client discovers the skill and its bundled guides.

2. Open the setup folder in that client. Review optional native role templates
   before configuring them through the client-specific steps in the skill guide.

   Expected result: the chosen project boundary and approval settings are visible.
   Installing a skill does not activate agents, connect accounts or grant permissions.

## Plan, approve and execute

1. Start with this prompt:

   ```text
   Use the day-one-mac skill to inspect my Mac and propose setup for the
   capabilities in my worksheet. Do not make changes. Offer direct access,
   existing OmniRoute, local OmniRoute or gateway setup later. Include exact
   commands, affected paths, prerequisites, human steps and recovery.
   ```

   Expected result: a bounded plan based on the observed machine and your choices.

2. Approve the desired scope in the client, then carry out one capability at a time.

   Expected result: only the approved capabilities change. Client confirmations
   remain active. A changed destructive scope requires a new decision.

3. Ask for the check workflow to verify the results.

   Expected result: verified, incomplete, failed and not-checked results are
   separate. Installation alone is not evidence of working account access.

## Record and resume

With your approval, save private notes outside the installed skill, for example
in `session/progress.md` in the setup folder. Record the capability, installation
owner, intended change, command, observed version, result, remaining human step
and recovery location. Never record credentials.

Resume by opening the same folder, reading the notes and checking the current
machine. Do not repeat installations solely because chat history is unavailable.

## Update, remove and extend

Follow the skill guide's scoped update and removal commands. Preserve private
notes and custom agent files separately. Use [component lifecycle](../manual/lifecycle.md)
for developer applications and [adding capabilities](../../shared/reference/adding-capabilities.md)
for repository changes. Optional MCP connections and scheduling require their
own configuration and approval. No unattended setup job is installed.

<a id="prepare-a-workspace"></a>
