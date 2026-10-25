# Day One omniroute

Read the [OmniRoute recipe](../project/docs/setup/manual/ai/omniroute.md) and
[AI bootstrap](../project/docs/setup/ai/bootstrap.md).

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
