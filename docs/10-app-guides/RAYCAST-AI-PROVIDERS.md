[← Raycast setup](RAYCAST.md) · **Raycast AI providers** · [Day One commands](RAYCAST-COMMANDS.md) · [AI clients](../02-optional/10-ai-agents.md)

# Choose and configure a Raycast AI provider

**When:** after required Phase 8 · **Required:** no · **Marker:** 🤖 ⚙️ Optional

Raycast works as an application launcher without AI, an API key or a paid
plan. Use this guide only when Raycast AI was deliberately selected and the
provider is permitted on this Mac.

## Choose one starting route

Start with one route so cost, account ownership and data flow remain clear.
Add a second route later only for a defined reason.

| Choice | Use it when | Account and cost | Request path |
|---|---|---|---|
| No Raycast AI | Launcher, File Search and Script Commands are enough | No AI plan | No AI prompt is sent |
| Built-in Raycast AI | The simplest supported setup is wanted | Raycast AI plan | Raycast-managed model route |
| Bring Your Own Key (BYOK) | You already use Anthropic, Google, OpenAI or OpenRouter | Paid Raycast plan plus provider usage | Varies by provider; review the privacy note below |
| Custom Provider | You use OmniRoute, LiteLLM, LM Studio or an approved OpenAI-compatible gateway | Paid Raycast plan plus provider usage | Direct from this Mac to the configured endpoint |
| Local Ollama model | Local/offline text processing is wanted and the Mac has enough memory | Paid Raycast plan; local disk and compute | Local Ollama service |
| Company-managed provider | Work policy supplies an approved gateway | Organisation policy and billing apply | Company-approved endpoint |

> **Work Mac:** confirm the organisation's AI-provider, data-retention and API-key
> rules before adding a personal account or key. If approval is unclear, choose
> **No Raycast AI** and continue using the required launcher features.

## Option 1 — Leave Raycast AI unconfigured

This is a complete and supported Day One outcome:

1. Do not add an API key or provider file.
2. Do not assign the optional Quick AI hotkey.
3. Keep using Claude Code, Codex or Copilot independently from Warp or VS Code.
4. Use [Day One Script Commands](RAYCAST-COMMANDS.md) for setup checks and
   documentation; they do not need Raycast AI.

## Option 2 — Use built-in Raycast AI

1. Open **Raycast Settings → AI**.
2. Sign into the intended personal or work Raycast account.
3. Confirm that the displayed plan and organisation are correct.
4. Keep tool approval on **Ask** and leave globally allowed tools empty.
5. Choose a default model whose data handling is approved.
6. Assign `⌥Space` to Quick AI only if it does not conflict with another app.
7. Send a harmless prompt such as `Summarise the difference between Git and GitHub`.
8. Check Raycast's usage view and confirm the expected account handled it.

## Option 3 — Bring Your Own Key

Raycast's graphical BYOK screen supports Anthropic, Google, OpenAI and
OpenRouter. Create a key specifically for Raycast rather than reusing a key
from a server, CI system or another AI client.

1. Open **Raycast Settings → AI → Models & Providers**.
2. In **API Keys**, choose **Add API Key**.
3. Select the provider.
4. Use **Manage in Provider Console** or open the provider's official console.
5. Create a dedicated key and set spend or usage limits where supported.
6. Paste it into Raycast, choose **Verify**, then **Save**.
7. Confirm the provider appears and its models show the key indicator.
8. Send one harmless request and inspect provider-side usage.
9. Record the provider console where the key can later be rotated or revoked.

Raycast documents an important privacy difference: Anthropic, Google and
OpenAI BYOK requests pass through Raycast's servers for API unification and
prompt handling, while OpenRouter BYOK requests go directly to OpenRouter.
Review the current [BYOK documentation](https://manual.raycast.com/ai/bring-your-own-key)
before choosing the route.

To pause a key without removing it, turn off its toggle in the API Keys list.
To retire it, remove it from Raycast **and** revoke it in the provider console.

## Option 4 — Configure an OpenAI-compatible custom provider

This route is for gateways and proxies whose chat endpoint is compatible with
Raycast's documented OpenAI-style interface. Compatibility is not guaranteed
merely because a product describes itself as OpenAI-compatible; verify its
model identifiers and supported request fields.

### Create or safely extend the provider file

1. Open **Raycast Settings → AI → Models & Providers**.
2. Scroll to **Custom Providers** and choose **Reveal Providers Config**.
3. Raycast creates this documented template:

   ```text
   ~/.config/raycast/ai/providers.template.yaml
   ```

4. If no live file exists, copy the template:

   ```bash
   cp "$HOME/.config/raycast/ai/providers.template.yaml" \
     "$HOME/.config/raycast/ai/providers.yaml"
   ```

5. If a live file already exists, back it up before editing:

   ```bash
   mkdir -p "$HOME/.day-one-mac/manual-backups"
   cp "$HOME/.config/raycast/ai/providers.yaml" \
     "$HOME/.day-one-mac/manual-backups/raycast-providers.before-change.yaml"
   ```

6. Keep the one existing top-level `providers:` key and add an indented entry
   beneath it. Do not create a second `providers:` key:

   ```yaml
   providers:
     - id: my_gateway
       name: My Approved Gateway
       base_url: https://gateway.example.com/v1
       api_keys:
         gateway: "<dedicated-raycast-api-key>"
       models:
         - id: "<exact-model-id>"
           name: "My Model"
           provider: gateway
           description: "Model through my approved gateway"
   ```

7. Restrict the file to this macOS account:

   ```bash
   chmod 600 "$HOME/.config/raycast/ai/providers.yaml"
   ```

8. Save it and return to Raycast. Raycast watches the file, so a valid provider
   should appear without restarting the app.
9. Select the model in Quick AI or AI Chat and send one harmless prompt.

Do not append `/chat/completions` to `base_url`; the base URL ends at the API
root expected by the gateway, commonly `/v1`.

### Understand the fields

| Field | Purpose |
|---|---|
| `id` | Unique local identifier for this provider entry |
| `name` | Provider name shown in Raycast |
| `base_url` | Compatible API root, without `/chat/completions` |
| `api_keys` | Key aliases and their local secret values; omit only when the endpoint needs no authentication |
| `models` | Models Raycast should add to its picker |
| model `id` | Exact identifier expected by the endpoint |
| model `provider` | Selects an alias from `api_keys` |
| `context` | Optional verified context size |
| `abilities` | Optional verified support for temperature, vision, system messages, tools and reasoning effort |
| `additional_parameters` | Optional fields added to every provider request |
| `include_user_email` | Sends the signed-in Raycast email as a header; use only for an approved shared gateway |

When an ability is not declared, Raycast assumes system messages and
temperature are supported, while vision and tools are not. Never declare a
capability only because the underlying model normally supports it: the gateway
must also pass that feature correctly.

## Option 5 — Connect OmniRoute running through OrbStack

Complete [Optional 10A — OmniRoute](../02-optional/10a-omniroute.md) first. OrbStack
provides the Docker engine; Raycast connects to the port published by the
OmniRoute container on macOS.

Use a dedicated endpoint key named for Raycast, not an upstream provider key:

```yaml
providers:
  - id: omniroute
    name: OmniRoute (Local)
    base_url: http://127.0.0.1:20128/v1
    api_keys:
      omniroute: "<dedicated-raycast-local-key>"
    models:
      - id: "<exact-model-id-from-omniroute>"
        name: "OmniRoute — <friendly-model-name>"
        provider: omniroute
        description: "Local route through OmniRoute on this Mac"
```

Verify all four parts:

1. OrbStack is running and its Docker context is active.
2. The OmniRoute container is healthy and publishes `127.0.0.1:20128`.
3. The model ID exactly matches a model exposed by OmniRoute.
4. A Raycast request appears in the OmniRoute dashboard under the intended route.

Stopping OrbStack or OmniRoute makes this provider unavailable; it does not
break Raycast's required launcher features.

## Option 6 — Use a local Ollama model

Raycast supports Ollama natively, so prefer this route over a custom-provider
entry for a normal local Ollama installation.

1. Install Ollama only when local models are wanted and approved.
2. Open **Raycast Settings → AI → Models & Providers → Local Models**.
3. Install a model there, or install one separately with `ollama pull`.
4. Choose **Sync Models** if an installed model does not appear.
5. Select it in the model picker and send a harmless test prompt.
6. Monitor memory and disk use; larger models need more of both.

For a remote Ollama host, enter its approved URL in **Ollama Host**. Raycast
does not start or secure a remote server. See the current
[Local Models documentation](https://manual.raycast.com/ai/local-models).

## Protect the provider file and keys

`providers.yaml` stores custom-provider keys as readable local text. Therefore:

- keep `~/.config/raycast/ai/providers.yaml` out of Git, chezmoi, Warp Drive,
  screenshots and ordinary support bundles;
- never put a key in a Raycast Script Command, Quicklink, alias or shell history;
- use one dedicated, revocable key per client;
- use provider-side spend limits and review usage;
- keep permissions at `600`; and
- back up only a redacted `providers.example.yaml`, never the live file.

If chezmoi manages `.config/raycast`, add this source-state exclusion before
running `chezmoi add`:

```text
.config/raycast/ai/providers.yaml
```

Then confirm the secret is not managed:

```bash
if chezmoi managed | grep -Fq '.config/raycast/ai/providers.yaml'; then
  echo 'STOP: remove the live provider file from chezmoi source state'
else
  echo 'OK: the live provider file is not managed by chezmoi'
fi
```

## Change or remove a provider later

1. Back up the current local file privately.
2. Remove only the intended `- id: ...` provider block.
3. Preserve the single top-level `providers:` list and every unrelated entry.
4. Save and confirm the other providers still load.
5. Revoke the removed provider's key at its source.
6. Confirm its models disappear from the Raycast model picker.

For BYOK, remove or disable the entry through Raycast Settings instead of
editing `providers.yaml`.

## Troubleshooting

| Symptom | Check |
|---|---|
| **Invalid providers.yaml** | Hover over Raycast's badge; fix the exact YAML error and keep one top-level `providers:` key |
| Provider appears with no models | Confirm every model has the exact endpoint model ID |
| `401` or `403` | Replace or re-scope the dedicated client key; do not paste an upstream key into OmniRoute |
| `404` | Check `base_url`; omit `/chat/completions` and verify the gateway API root |
| Tools, images or reasoning fail | Remove optimistic `abilities` entries until the model and route are verified |
| OmniRoute model is offline | Start OrbStack and OmniRoute, then verify the published loopback port |
| Key works but cost is unexpected | Disable it in Raycast, inspect provider usage, then apply provider-side limits |
| Personal provider is blocked | Remove it and use only the organisation-approved route |

## Completion checklist 🚦

- [ ] Raycast AI is deliberately enabled or deliberately left unconfigured.
- [ ] Exactly one starting provider route is understood.
- [ ] The provider account is appropriate for this Mac and data classification.
- [ ] A dedicated key and spend limit are used where possible.
- [ ] Tool approvals remain on **Ask** and globally allowed tools are empty.
- [ ] A harmless test reached the expected provider or local model.
- [ ] `providers.yaml`, when present, has mode `600` and is outside Git and chezmoi.
- [ ] The key's rotation and revocation location is known.

Official references: [Custom Providers](https://manual.raycast.com/ai/custom-providers),
[Bring Your Own Key](https://manual.raycast.com/ai/bring-your-own-key), and
[Local Models](https://manual.raycast.com/ai/local-models).

---

[← Raycast setup](RAYCAST.md) · [Configure Day One commands](RAYCAST-COMMANDS.md) · [Configure AI clients →](../02-optional/10-ai-agents.md)
