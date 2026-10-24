# Prepare the AI client and connection

Establish one working client and its provider connection before asking AI to
configure the rest of the Mac. This bootstrap can be completed manually.

## Prerequisites

Read [shared prerequisites](../../shared/prerequisites.md). Confirm account,
network and organisation approval. Keep backup/reset preparation ahead of local
installation; browser guidance can help while no local client is available.

## Choose the mode and client

1. Choose guidance only or approved local execution.

   Expected result: you know whether you or the client will run commands.
   Guidance does not need a local execution tool.

2. Reuse an approved client, or follow the
   [manual client bootstrap](../manual/ai/setup-assistant.md#2-reuse-a-client-or-review-one-native-installer).
   Codex and Claude Code have native CLI paths; Copilot requires its chosen app
   or editor and account setup. Install only one client initially.

   Expected result: the selected client opens and its version is recorded.
   Account sign-in and model access still need verification.

## Choose direct access or OmniRoute

| Choice | Prerequisites | Next action |
|---|---|---|
| Direct provider access | Supported client and approved account | Sign in using the client's own instructions |
| Existing OmniRoute | Approved endpoint and provider route | Verify the endpoint and chosen client |
| Local OmniRoute | Native package runtime or a selected container engine | Follow the [OmniRoute recipe](../manual/ai/omniroute.md) |
| Gateway later | Working direct connection | Continue; keep gateway setup as a separate task |

1. Record one connection choice in private notes.

   Expected result: a selected provider route and installation owner. A gateway
   is optional and does not replace the AI client.

2. Complete the selected route. For local containers, prepare Docker Desktop or
   OrbStack first and verify its context before creating the gateway. For native
   OmniRoute, prepare its documented Node runtime first. These are bootstrap
   prerequisites, not reasons to complete the entire developer setup first.

   Expected result: the endpoint is reachable and one provider is configured.
   The user enters provider credentials and endpoint keys in their own interfaces.

3. Send a harmless request through the chosen client, such as asking it to reply
   with the word `ready`. In execution mode, separately approve a read-only
   command such as `uname -m`.

   Expected result: a model response and, when selected, `arm64` from the local
   command. Gateway health alone does not verify tool use or client compatibility.

4. Continue with the [assistant workspace](operation.md#prepare-a-workspace).

   Expected result: the assistant receives the selected scope and canonical recipes.

## Troubleshooting and recovery

If authentication or model access fails, stop dependent setup. Check the chosen
client's account and gateway instructions. Do not switch providers or billing
routes silently. Use manual guidance until the connection works.

Keep an existing client installation and its update owner. Installing another
copy to fix a PATH problem can create conflicting ownership. Do not disable TLS
verification to work around package-download certificate errors.
