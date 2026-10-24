---
name: day-one-omniroute
description: Set up, inspect or maintain an explicitly selected local or existing OmniRoute gateway for an AI client. Use for gateway onboarding and connection problems.
---

# Day One omniroute

Read the [OmniRoute recipe](references/project/docs/setup/manual/ai/omniroute.md) and
[AI bootstrap](references/project/docs/setup/ai/bootstrap.md).

Confirm that a gateway is wanted. Choose one installation owner: existing
service, native package or reviewed container. Prepare only that owner's
prerequisites before depending on the gateway for AI setup.

For containers, verify the selected local engine/context, reviewed image digest,
loopback port and resource ownership. Do not adopt another container or volume,
change the global Docker context or prune resources. Preserve provider data.

Provider authentication and the gateway endpoint key are different credentials.
The user enters them in the appropriate client/dashboard. Never request tokens
in chat. Verify the selected client's protocol, authentication and model with
one harmless request; a healthy container alone is insufficient.

Do not change fallback providers, billing routes, client settings or enable MCP
without the user's selected scope. If the gateway fails, offer the manual route
or an explicitly selected direct-provider connection.

## Installed package

Resolve bundled links relative to this skill directory, not the working directory.
The project reference snapshot is under `references/project/`; use its matching
paths when a guide refers to supplied configuration or template files. Read only
the guide needed for the current task. Keep this installed package unchanged.

The skill is already available after installation. Workspace export is an
optional alternative; do not require it to begin. Save approved private notes
in a user-selected workspace. The optional `day-one-mac` utility command needs
a separate installation; use the manual recipes when that command is absent.
