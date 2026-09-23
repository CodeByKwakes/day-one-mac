[← AI clients](10-ai-agents.md) · **🤖 ⚙️ Optional 10A** · [MCP servers →](11-mcp-servers.md)

# Optional 10A — OmniRoute AI gateway in Docker

**Time:** 40–75 minutes · **Required:** no · **Prerequisites:** Phase 8, one
selected AI client from Optional 10, and OrbStack running its Docker engine

## Outcome

OmniRoute runs in one local Docker container, listens only on this Mac, and
keeps its data in a named Docker volume. Only the AI clients selected in the
Day One wizard are connected. Raycast can use it as a custom AI provider, and
Warp can launch the selected terminal clients through it. Normal provider
login remains available, and no provider credential or OmniRoute key is
committed to Git or written literally into a shell startup file.

Use this module when one local gateway should expose models from multiple
approved providers, provide a common endpoint, or offer routing and fallback.
Skip it when each client should connect directly to its own provider. Skipping
OmniRoute does not affect the required Day One setup.

This guide was checked against OmniRoute `release/v3.8.51`. OmniRoute and the
clients change frequently, so compare the linked upstream documentation before
applying a newer release.

To add OmniRoute to an existing Day One plan, rerun the wizard, choose
**Review or change setup choices**, and toggle both **OmniRoute AI gateway** and
the clients that should use it:

```bash
cd "$(day-one-mac root)/scripts"
./bootstrap-day-one-mac.sh --wizard
```

The choice is saved to the review report; it does not start a container or
alter a client automatically.

## Minimum working route

For the shortest successful setup, complete one client before adding the rest:

1. Start OrbStack and select its Docker context.
2. Start OmniRoute on the loopback address so it is reachable only from this Mac.
3. Add one approved model provider.
4. Create one endpoint key for local clients.
5. Configure one selected AI client.
6. Run one harmless read-only request, then add other clients only as needed.

## Understand the three parts

| Part | Plain-English purpose | Where it runs |
|---|---|---|
| OmniRoute server | Receives model requests and routes them to a connected provider | Docker on this Mac |
| Provider connection | Gives OmniRoute access to an approved model service; it may use OAuth or a provider API key | Stored in the `omniroute-data` Docker volume |
| Endpoint key | Lets a local client call this OmniRoute server; it is not the provider's account key | Loaded privately by each client |

The request path is:

```text
Raycast or a Claude/Codex/Copilot CLI command started in Warp
                    │
                    ▼
       http://127.0.0.1:20128 on macOS
                    │
                    ▼
       OrbStack Docker engine → OmniRoute container
                    │
                    ▼
             approved AI provider
```

OrbStack is the container engine. OmniRoute does not connect to a separate
OrbStack service, and the `docker run` command does not need an OrbStack-only
flag. The Docker command sends work to whichever Docker **context** is active;
Step 10A.2 makes the OrbStack context explicit before anything is created.

OmniRoute is an **AI gateway**, not an MCP server. It routes model requests.
Claude Code, Codex, or VS Code still controls files, Terminal commands, MCP
tools, and approval prompts. Keep those approval prompts enabled.

Requests and any attached code pass through OmniRoute and then the selected
model provider. On a work Mac, confirm that both services are allowed before
sending company code. Provider billing, quotas, and retention rules still
apply.

## Step 10A.1 — Confirm the selected clients and app surfaces

Open the saved wizard review:

```bash
open "$HOME/.day-one-mac/wizard-selections.md"
```

Complete only the matching sections below:

| Client or app surface | Follow in this guide | Address format |
|---|---|---|
| Claude Code | Step 10A.6 | `http://127.0.0.1:20128` — no `/v1` |
| Codex | Step 10A.7 | `http://127.0.0.1:20128/v1` |
| GitHub Copilot in VS Code | Step 10A.8 | Server root, with no `/v1` |
| GitHub Copilot app | Step 10A.8A | `http://127.0.0.1:20128/v1` as an OpenAI-compatible provider |
| GitHub Copilot CLI | Step 10A.9 | Copy the version-specific config shown by OmniRoute |
| Raycast AI | Step 10A.10 | `http://127.0.0.1:20128/v1` |
| Warp | Step 10A.11 | Launch a selected terminal client in the same Warp tab that loaded the key |

Do not configure an unselected client just because it appears in the
dashboard.

## Step 10A.2 — Start OrbStack and select its Docker context

This module needs Docker commands but does not need Docker Compose or a
database. If OrbStack was not installed for Optional 9, install and open it:

```bash
day-one-mac applications --id orbstack --install-missing
open -a OrbStack
```

The check accepts a valid Company Portal or manual installation and does not
add a second Homebrew-owned copy. If OrbStack is missing, choose Homebrew or an
approved external installer; after the external installer finishes, press Enter
so Day One Mac verifies it before you continue.

Wait until OrbStack says Docker is running. Now list Docker's available
contexts and show the active one:

```bash
docker context ls
docker context show
```

The active context must be `orbstack`. If `orbstack` appears in the list but is
not active, switch deliberately:

```bash
docker context use orbstack
```

If `orbstack` is missing, quit and reopen OrbStack. Do not create the container
under `desktop-linux`, `colima`, or another context and then switch: containers,
images, and named volumes belong to the engine in which they were created.

Finally, check both halves of Docker:

```bash
docker version
```

The output must contain both **Client** and **Server** sections and should show
`Context: orbstack`. If only the Client appears, the Docker engine is not ready.
Open OrbStack and retry.

Check whether port 20128 is already in use:

```bash
lsof -nP -iTCP:20128 -sTCP:LISTEN || true
```

No output means the port is free. If another application is listed, stop and
choose whether to stop that application or use a different host port. When a
different port is used, replace `20128` in every later client address.

## Step 10A.3 — Run OmniRoute locally

First check whether that container name is already owned:

```bash
if docker container inspect omniroute >/dev/null 2>&1; then
  echo "An omniroute container already exists — review it before starting it"
  docker inspect omniroute \
    --format 'Image={{.Config.Image}} Ports={{json .HostConfig.PortBindings}} Mounts={{range .Mounts}}{{.Name}}:{{.Destination}} {{end}}'
else
  echo "No existing omniroute container — the name is available"
fi
```

If a container exists, do not replace or start it until its image, host port,
and volume ownership are understood. If it is a previous container created by
this guide, use `docker start omniroute` and continue to verification. If the
name is available, the following command uses the official image, persists
application data, and binds the service to `127.0.0.1`. That address means
other devices on the local network cannot connect. API-key enforcement is
enabled even on the local endpoint.

The memory settings follow OmniRoute's published starting point for one coding
agent. `--memory=10g` is a ceiling, not an immediate reservation. Run one long
coding session at a time and skip this module if the Mac cannot safely make
that memory available.

```bash
docker pull diegosouzapw/omniroute:latest
docker volume create omniroute-data
docker run -d \
  --name omniroute \
  --label com.day-one-mac.module=omniroute \
  --restart unless-stopped \
  --stop-timeout 40 \
  --memory=10g \
  -e OMNIROUTE_MEMORY_MB=8192 \
  -e REQUIRE_API_KEY=true \
  -p 127.0.0.1:20128:20128 \
  -v omniroute-data:/app/data \
  diegosouzapw/omniroute:latest
```

Why these options matter:

- `omniroute-data` keeps configuration when the container is recreated.
- That named volume is stored by the active OrbStack Docker engine. It will not
  appear after switching to Docker Desktop or another context, and it is not an
  independent backup.
- `--stop-timeout 40` gives the database time to finish writing on shutdown.
- `--restart unless-stopped` restarts the service with the Docker engine unless
  you deliberately stopped it.
- The `base` image behavior is sufficient because Claude Code, Codex, and VS
  Code run on macOS. Do not mount the Docker socket or your complete home folder
  into the container.

`latest` is convenient for the first evaluated install, but it can change.
After the setup passes, record the exact downloaded digest:

```bash
docker image inspect diegosouzapw/omniroute:latest \
  --format '{{index .RepoDigests 0}}'
```

Use a tested version tag or digest when the same build must be reproduced on a
team. Never replace a running production-like gateway merely because `latest`
changed; read the release notes and back up the volume first.

## Step 10A.4 — Complete the dashboard setup

1. Open <http://127.0.0.1:20128> in a browser.
2. If a first-run administrator setup appears, create its password and save it
   in 1Password.
3. Open **Providers** and connect only services that this Mac is allowed to use.
4. Prefer the provider's browser sign-in when available. If an API key is
   required, copy it directly from 1Password into the dashboard; do not put it
   in this repository or a command.
5. Open **API Manager** at
   <http://127.0.0.1:20128/dashboard/api-manager>.
6. Create a separate endpoint key named `day-one-local-clients`. Give it only
   the model-list and inference permissions required by the clients when the
   current interface offers permission choices.
7. Copy the endpoint key once and create a 1Password **Password** item named
   **OmniRoute Endpoint - Day One Mac**. Put the key in its `password` field and
   put `day-one-local-clients` in its username or notes so its purpose is clear.
8. If Raycast AI was selected, create a second key named `raycast-local` with
   the same minimal model-list and inference permissions. Save it as a separate
   field or item in 1Password. Raycast's supported custom-provider format keeps
   its key in a local YAML file, so a dedicated key limits the impact of that
   file being exposed and can be revoked without disconnecting terminal clients.
9. If the GitHub Copilot app was selected, create a separate key named
   `copilot-app-local`. The app stores provider credentials in the macOS system
   credential store, and a distinct key can be revoked without disconnecting
   the terminal clients.
10. Optionally create a provider combination or fallback route. Begin with one
   provider and one model; add fallback only after the direct route works.

The provider credential and endpoint key are different secrets. Revoking the
endpoint key disconnects local clients without revoking the provider account.

## Step 10A.5 — Load the endpoint key safely and test it

There is no OmniRoute `.env` file in the Day One setup. `OMNIROUTE_API_KEY` is
the name of an environment variable held in the memory of the current shell
process. It has no filesystem location. Closing that Terminal or Warp tab, or
running `unset OMNIROUTE_API_KEY`, removes it from that shell.

The actual secret is stored in the 1Password item created in Step 10A.4. Replace
`<vault>` with that item's vault name, then load its `password` field into this
Terminal window:

```bash
export OMNIROUTE_API_KEY="$(op read \
  'op://<vault>/OmniRoute Endpoint - Day One Mac/password')"
```

For example, if the item is in a vault named `Developer`, the reference is:

```bash
export OMNIROUTE_API_KEY="$(op read \
  'op://<vault>/OmniRoute Endpoint - Day One Mac/password')"
```

Check that a value was loaded without printing the secret:

```bash
if [[ -n "${OMNIROUTE_API_KEY:-}" ]]; then
  echo "OmniRoute endpoint key is loaded in this tab"
else
  echo "OmniRoute endpoint key is not loaded"
fi
```

If the 1Password CLI is unavailable, read the key without echoing it on screen:

```bash
printf 'Paste the OmniRoute endpoint key, then press Return: '
IFS= read -r -s OMNIROUTE_API_KEY
printf '\n'
export OMNIROUTE_API_KEY
```

The key exists only in this Terminal process and its child processes. Do not
place the literal value in a project `.env`, `.zshrc`, `.zprofile`, a chezmoi
template, a JSON or TOML file, a screenshot, or a Git repository. A normal
project `.env` belongs to that project's runtime; it is not a safe machine-wide
credential store for this gateway.

Confirm the server and list its available model IDs:

```bash
docker ps --filter 'name=^/omniroute$'
curl -fsS \
  -H "Authorization: Bearer $OMNIROUTE_API_KEY" \
  http://127.0.0.1:20128/v1/models |
  jq -r '.data[].id' | sort | head -30
```

If the first command does not show an `Up` container, inspect its recent log:

```bash
docker logs --tail 100 omniroute
```

If the model request returns `401` or `403`, create or recopy the endpoint key.
If it returns no usable models, finish the provider connection in the dashboard
before changing a client.

## Step 10A.6 — Connect Claude Code

Skip this step unless Claude Code was selected and `claude --version` works.

For a reversible first test, use only the current Terminal window:

```bash
export ANTHROPIC_BASE_URL="http://127.0.0.1:20128"
export ANTHROPIC_AUTH_TOKEN="$OMNIROUTE_API_KEY"
claude
```

The Claude address deliberately has **no `/v1` suffix**. Claude Code appends
its own API paths. Ask a small read-only question first and confirm the
OmniRoute dashboard records the request against the intended provider.

To return to the normal Claude route in this Terminal window:

```bash
unset ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN
```

Do not copy the endpoint key into `~/.claude/settings.json`. If a permanent
launcher is added later, let it read the key from 1Password at launch time and
keep the normal `claude` command unchanged.

## Step 10A.7 — Connect Codex CLI with a separate profile

Skip this step unless Codex was selected and `codex --version` works. This
configures **Codex CLI**. It does not replace the ChatGPT/Codex desktop app's
normal workspace sign-in or cloud service.

First back up the existing user configuration:

```bash
mkdir -p "$HOME/.day-one-mac/manual-backups"
cp "$HOME/.codex/config.toml" \
  "$HOME/.day-one-mac/manual-backups/codex-config.before-omniroute.toml" \
  2>/dev/null || true
```

Open `~/.codex/config.toml` and merge this provider block exactly once. Do not
replace unrelated settings:

```toml
[model_providers.omniroute]
name = "OmniRoute"
base_url = "http://127.0.0.1:20128/v1"
env_key = "OMNIROUTE_API_KEY"
requires_openai_auth = false
wire_api = "responses"
```

Next create `~/.codex/omniroute.config.toml` as a separate Codex profile:

```toml
model_provider = "omniroute"
model = "<responses-capable-model-id-from-OmniRoute>"
```

Replace the complete placeholder with an ID returned by Step 10A.5 that
OmniRoute exposes on `/v1/responses`. The separate profile prevents OmniRoute
from becoming the default for normal Codex sessions.

Start the alternate profile from the Terminal window where
`OMNIROUTE_API_KEY` is loaded:

```bash
codex --profile omniroute
```

Start normal Codex without the profile to use the original configuration:

```bash
codex
```

Current Codex profile files live beside `config.toml` and use the name
`<profile>.config.toml`. Do not use the retired `[profiles.omniroute]` table.
Keep approval prompts and the normal sandbox enabled while testing a new model
route.

## Step 10A.8 — Connect GitHub Copilot Chat in VS Code

Skip this step unless **GitHub Copilot in VS Code** was selected. OmniRoute's
supported integration is the separate OmniCopilot model-provider extension:

```bash
code --install-extension diegosouzapw.omnicopilot
```

Then configure it:

1. Restart VS Code.
2. Press `⌘⇧P` and run **OmniRoute: Manage Connection**.
3. Enter `http://127.0.0.1:20128` as the server URL. Do not append `/v1`.
4. Paste the `day-one-local-clients` endpoint key when requested. The extension
   stores it through VS Code SecretStorage, backed by the macOS Keychain, rather
   than `settings.json`.
5. Open Chat and use the model picker.
6. Choose **Manage Models… → OmniRoute** and tick only the models you intend to
   use.
7. Select one of those models and send a small read-only chat request.
8. Confirm the request appears under the expected provider in OmniRoute.

This adds OmniRoute models to the native Copilot Chat model picker. It does not
route native inline completions or embeddings. Those features still use GitHub
Copilot and may still require GitHub sign-in and a Copilot entitlement. Keep
the Day One `chat.tools.*.autoApprove` settings disabled.

To stop using OmniRoute in VS Code, choose a normal GitHub-provided model in
the picker, disconnect the OmniRoute connection, or uninstall only this
extension:

```bash
code --uninstall-extension diegosouzapw.omnicopilot
```

## Step 10A.8A — Connect the GitHub Copilot app

Skip this step unless the standalone **GitHub Copilot app** was selected and
installed. The app supports an OpenAI-compatible HTTP endpoint through its own
model-provider settings.

1. Open the GitHub Copilot app and then open **Settings → Model providers**.
2. Choose **Add provider** and select the OpenAI-compatible provider option.
3. Use a clear display name such as `OmniRoute local`.
4. Enter `http://127.0.0.1:20128/v1` as the base URL.
5. Paste the dedicated `copilot-app-local` endpoint key from 1Password.
6. Save the provider. The app stores its credential in the macOS system
   credential store rather than a dotfile.
7. In a disposable repository, start an **Interactive** or **Plan** session,
   choose one OmniRoute-backed model, and make a read-only request.
8. Confirm that the request appears under the expected provider in OmniRoute.

To return to GitHub-hosted models, choose one in the app's model picker. To
disconnect OmniRoute, remove only the `OmniRoute local` provider and revoke its
dedicated endpoint key. Do not place that key in the repository or shell
startup files.

## Step 10A.9 — Connect GitHub Copilot CLI

Skip this step unless the separate Copilot CLI was selected and
`copilot --version` works.

Copilot CLI configuration changes between releases. Do not copy a guessed path
or old static example. Instead:

1. Open <http://127.0.0.1:20128/dashboard/cli-code>.
2. Select **GitHub Copilot CLI**.
3. Select the `day-one-local-clients` key and the local server address.
4. Choose **Copy manual config**, not **Apply Config**.
5. Confirm the generated target and fields match the help/configuration output
   of the installed `copilot` release.
6. Back up that exact host file under
   `~/.day-one-mac/manual-backups/` before merging the generated fields.
7. Start Copilot CLI and send a small read-only request.
8. Confirm the request appears in OmniRoute and that the normal Copilot login
   still works after the custom route is disabled.

Why manual copy is required: OmniRoute runs inside Docker. An **Apply Config**
action would target the container's home folder, not the macOS user's files,
and a correctly protected OmniRoute container refuses that write. Do not bind
mount `~/.copilot`, `~/.codex`, or `~/.claude` merely to bypass this boundary.

## Step 10A.10 — Connect Raycast AI

Skip this step unless **Raycast AI** was selected. The Raycast app is already a
required Installation Centre install, but Custom Providers require a paid Raycast plan.
This connection uses Raycast's supported OpenAI-compatible provider interface;
it is separate from Raycast's built-in models and does not consume Raycast AI
credits. Provider usage and billing still apply.

If you have not yet chosen between built-in Raycast AI, BYOK, local Ollama and
a custom gateway, read the [Raycast AI provider decision guide](../10-app-guides/RAYCAST-AI-PROVIDERS.md)
first. This section remains the canonical OmniRoute-specific configuration;
the provider guide covers the alternatives and shared secret-handling rules.

### Create the local provider file

1. Open **Raycast Settings → AI → Models & Providers**.
2. Scroll to **Custom Providers** and choose **Reveal Providers Config**.
3. Raycast creates `~/.config/raycast/ai/providers.template.yaml`. If
   `providers.yaml` does not exist, copy the template to that name. If it does
   exist, merge the OmniRoute entry into its existing top-level `providers`
   list; do not replace other providers.
4. Before editing an existing file, make a private backup:

   ```bash
   mkdir -p "$HOME/.day-one-mac/manual-backups"
   cp "$HOME/.config/raycast/ai/providers.yaml" \
     "$HOME/.day-one-mac/manual-backups/raycast-providers.before-omniroute.yaml" \
     2>/dev/null || true
   ```

5. Add this one provider entry. Replace both complete placeholders. Use an
   exact model ID returned by Step 10A.5 that accepts OpenAI-compatible chat
   requests, and paste the dedicated `raycast-local` endpoint key—not an
   upstream provider key:

   ```yaml
   providers:
     - id: omniroute
       name: OmniRoute (Local)
       base_url: http://127.0.0.1:20128/v1
       api_keys:
         omniroute: "<paste-the-dedicated-raycast-local-key>"
       models:
         - id: "<exact-chat-model-id-from-omniroute>"
           name: "OmniRoute — <friendly-model-name>"
           provider: omniroute
           description: "Local route through OmniRoute on this Mac"
   ```

   If `providers:` already exists, add only the indented `- id: omniroute`
   block beneath it. A YAML file cannot contain two top-level `providers:`
   keys.

6. Restrict the file to the current macOS account:

   ```bash
   chmod 600 "$HOME/.config/raycast/ai/providers.yaml"
   ```

7. Keep this file out of Git, chezmoi, Warp Drive, screenshots, and support
   bundles. Unlike the terminal integrations, Raycast's current documented
   format stores the key in this machine-local file. This is why the dedicated,
   revocable key and restrictive file permission are required.

### Verify Raycast

Raycast watches the file without a restart. Return to **Custom Providers**:

1. Confirm **OmniRoute (Local)** appears with the expected model count.
2. If **Invalid providers.yaml** appears, hover over it and correct the exact
   YAML error Raycast reports.
3. Open Quick AI or AI Chat and choose the OmniRoute model in the model picker.
4. Send one small, read-only prompt.
5. Confirm the request appears in the OmniRoute dashboard under the intended
   route.

Do not declare `tools`, `vision`, `reasoning_effort`, or a context-window size
until the chosen model and route are confirmed to support them. Raycast uses
those fields to decide which features it may send; an optimistic value can make
requests fail.

To disconnect Raycast later, remove only the `id: omniroute` entry from
`providers.yaml`, confirm the other providers still load, and revoke the
`raycast-local` key in OmniRoute. Do not delete the complete file when it also
contains another custom provider.

## Step 10A.11 — Use OmniRoute from Warp

Warp is the required graphical terminal, not a supported generic
OpenAI-compatible client setting. The reliable integration is to start Claude
Code, Codex, or GitHub Copilot CLI from a Warp tab after loading the endpoint
key in that same tab.

1. Start OmniRoute under OrbStack and confirm the active engine:

   ```bash
   docker context show
   docker ps --filter 'name=^/omniroute$'
   ```

2. In the Warp tab that will run the AI client, load
   `OMNIROUTE_API_KEY` with the 1Password command in Step 10A.5.
3. For Claude Code, set `ANTHROPIC_BASE_URL` and `ANTHROPIC_AUTH_TOKEN` as in
   Step 10A.6, then run `claude` in that same tab.
4. For Codex, run `codex --profile omniroute` as in Step 10A.7.
5. For GitHub Copilot CLI, complete the version-specific manual configuration
   in Step 10A.9, then start `copilot` in that same tab.
6. Open a second fresh Warp tab and run the normal client command to prove that
   the standard direct-provider route was not replaced globally.

Do not save the endpoint key in a project `.env`, Warp Drive Environment
Variable, Workflow, Launch Configuration, Notebook, or synced shell startup
file. A child command inherits variables loaded in its own tab; another tab
does not have the key until you load it there separately.

Warp's built-in AI is a different service. Its public configuration supports
Warp-managed models, individual supported provider keys, and enterprise
bring-your-own-LLM arrangements, but it does not currently document a general
localhost OpenAI-compatible base URL for the desktop AI. Therefore this guide
does not pretend to route Warp AI itself through OmniRoute. OmniRoute's
`warp`/ACP catalogue entry describes OmniRoute launching Warp as a backend
agent; that is the reverse direction and is marked as partial support.

If Warp later publishes a supported custom-endpoint control, add it only after
checking the current Warp and OmniRoute guides. Do not rely on undocumented
environment-variable overrides for the Warp application.

## Step 10A.12 — Daily use, updates, backup, and removal

Daily container commands:

```bash
docker start omniroute
docker stop --time 40 omniroute
docker logs --tail 100 omniroute
docker stats --no-stream omniroute
```

Before an update, use OmniRoute's supported export/backup action if the current
dashboard provides one. At minimum, stop the container cleanly and include the
Docker or OrbStack data in an encrypted external backup. A named volume is
persistent storage, not an independent backup.

To remove only the container while preserving its configuration:

```bash
docker stop --time 40 omniroute
docker rm omniroute
```

Delete its saved configuration only after confirming that the backup or loss
is acceptable:

```bash
docker volume rm omniroute-data
```

Also remove the client-side provider/profile fields you merged, restore from
the named manual backup if appropriate, revoke the OmniRoute endpoint key, and
disconnect provider accounts in the dashboard before deleting the volume.
Removing the container alone does not revoke provider access.

The broad Day One cleanup preserves Docker/OrbStack data by default. When the
`--archive-docker-data` or `--archive-orbstack-data` option matching your
runtime is selected, the container data that contains `omniroute-data` is moved
into the recovery archive with other container state.

## Troubleshooting

| Symptom | What to check |
|---|---|
| Dashboard does not open | `docker ps` and `docker logs --tail 100 omniroute`; confirm the host port is 20128 |
| Container exits during a long coding request | Review Docker memory in `docker stats`; the image's light-use default is not enough for a coding agent |
| Client receives `401` or `403` | Reload the endpoint key; do not substitute the upstream provider key |
| No models appear | Reconnect the provider, check its quota, then retest `/v1/models` before the client |
| Claude reports a bad URL | Use the server root without `/v1` |
| Codex reports provider/model errors | Use `/v1`, a Responses-capable model ID, the `omniroute` profile, and a loaded `OMNIROUTE_API_KEY` |
| VS Code chat has OmniRoute but inline suggestions do not | Expected: OmniCopilot covers chat models, not native Copilot inline completions |
| Raycast reports `Invalid providers.yaml` | Hover over the badge for the exact YAML error; keep one top-level `providers:` key and an exact model ID |
| Raycast reports `401` or `403` | Recopy or replace only the dedicated `raycast-local` endpoint key; do not use the upstream provider key |
| A command launched in Warp bypasses OmniRoute | Load the endpoint key and client-specific configuration in that same tab, then use the matching Claude, Codex, or Copilot instructions from this guide |
| Warp AI has no OmniRoute model | Expected: the documented path uses Warp as the terminal for Claude/Codex/Copilot CLI; Warp AI has no supported generic local endpoint setting |
| `docker ps` shows no OmniRoute after it previously worked | Run `docker context show`; switch back to `orbstack` before assuming the container or volume was deleted |
| Dashboard cannot apply a host config | Expected in Docker: copy and merge the manual host snippet instead |
| Another computer cannot connect | Expected: the guide binds to loopback for local-only access; do not widen it casually |

## Optional completion checklist 🚦

- [ ] OmniRoute appears as `Up` in `docker ps`.
- [ ] Port 20128 is bound to `127.0.0.1`, not every network interface.
- [ ] `docker context show` reports `orbstack`.
- [ ] The `omniroute-data` volume exists and its backup policy is understood.
- [ ] Only approved providers are connected.
- [ ] A separate, least-privilege endpoint key exists for local clients.
- [ ] The endpoint key is stored in 1Password or the client's OS-backed secret
  store, not a repository or shell startup file.
- [ ] `/v1/models` succeeds with the endpoint key.
- [ ] Each selected client passes one read-only request.
- [ ] Raycast's machine-local provider file, when used, is mode `600`, is not
  managed by Git/chezmoi, and uses its own revocable endpoint key.
- [ ] Warp-launched clients work without storing a secret in Warp Drive or a
  shell startup file.
- [ ] Normal direct-provider use still works when the OmniRoute profile or
  environment variables are not selected.
- [ ] AI-client approval prompts remain enabled.
- [ ] Provider billing, retention, and work-device policy were reviewed.

Official project references: [OmniRoute Docker guide](https://github.com/diegosouzapw/OmniRoute/blob/release/v3.8.51/docs/guides/DOCKER_GUIDE.md),
[OmniRoute CLI-tool guide](https://github.com/diegosouzapw/OmniRoute/blob/release/v3.8.51/docs/20-reference/CLI-TOOLS.md),
[OmniRoute VS Code/Copilot guide](https://github.com/diegosouzapw/OmniRoute/blob/release/v3.8.51/docs/guides/VSCODE-COPILOT.md),
and [OmniCopilot source](https://github.com/diegosouzapw/OmniCopilot).
The Copilot desktop connection follows GitHub's
[own model provider guide](https://docs.github.com/en/copilot/how-tos/github-copilot-app/use-byok-models).
Raycast configuration is checked against the
[official Custom Providers guide](https://manual.raycast.com/ai/custom-providers).
OrbStack's role is checked against the
[official OrbStack overview](https://docs.orbstack.dev/), and Warp's limitation
is documented from its current
[bring-your-own-LLM guide](https://docs.warp.dev/enterprise/enterprise-features/bring-your-own-llm).
Codex provider and profile behavior is checked against the
[official OpenAI advanced configuration](https://learn.chatgpt.com/docs/config-file/config-advanced)
and [configuration reference](https://learn.chatgpt.com/docs/config-file/config-reference).

---

[← AI clients](10-ai-agents.md) · [MCP servers (optional) →](11-mcp-servers.md) · [Project home](../README.md)
