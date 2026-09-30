[← Manual handbook](README.md) · [Node.js toolchains](../01-required/06-language-toolchains.md)

# Configure npm access to Azure Artifacts on macOS

**Audience:** developers whose project downloads private npm packages from Azure
Artifacts. **Required:** only when your selected project uses this service.
**Outcome:** npm can retrieve a known private package using your own credentials.

This guide covers local development on macOS using npm. Publishing, Windows,
other package managers, and CI authentication need their own instructions.
Neither the Day One Mac CLI nor chezmoi is required. The CLI does not collect
the PAT described here; do not put it in setup state, logs, or acceptance evidence.

## Before you begin

You need:

- Node.js and npm installed, using the versions required by your project.
- Access to the relevant Azure DevOps organisation, project, and feed.
- Your team's feed URL, package scope if applicable, and a known private package.
- Permission to create an organisation-scoped personal access token, or your
  team's approved alternative authentication method.

A **feed** stores packages. A **registry URL** tells npm where to find them.
A **personal access token (PAT)** is a credential that identifies you to Azure
DevOps. A **package scope** is the `@team` part of a name such as `@team/library`.

Check your tools:

```sh
node --version
npm --version
```

If either command is unavailable, complete the
[Node.js toolchain setup](../01-required/06-language-toolchains.md) first. For a
fully manual installation, use [Manual 6](../20-reference/MANUAL-SETUP-GUIDE.md#manual-6--install-the-selected-language-toolchains).

Your Azure Repos SSH key, GitHub login, or `az login` session does not by itself
configure npm authentication. If employer policy requires credential tooling,
use that workflow instead of bypassing it with a PAT.

## 1. Understand which file stores what

npm combines configuration from several sources, including project and user
files. The project file does not load the user file itself. See the
[npm configuration reference](https://docs.npmjs.com/cli/v11/configuring-npm/npmrc/).

| File | Purpose | Commit to Git? |
|---|---|---|
| Project `.npmrc`, beside `package.json` | Registry routing and non-secret project settings | Yes, after review |
| User `.npmrc`, usually `~/.npmrc` | Credentials for matching registry URLs | **No, when it contains credentials** |

Find your actual user configuration path:

```sh
npm config get userconfig
```

Use that returned path throughout this guide. Do not assume another developer's
`/Users/...` path applies to your Mac. Preserve unrelated settings in an existing
file. If it is managed by chezmoi or linked into a repository, resolve that
ownership before adding credentials; see the chezmoi note below.

## 2. Get the correct feed configuration

In Azure DevOps, open your project, then **Artifacts → selected feed → Connect
to feed → npm**. Choose the applicable macOS instructions.

Use the supplied project configuration in the project's `.npmrc`. Keep an
existing team-approved configuration unless your maintainer directs a change.
Organisation-scoped and project-scoped feed URLs differ; copy the exact URL.
See [Microsoft's connection guide](https://learn.microsoft.com/en-us/azure/devops/artifacts/npm/npmrc?view=azure-devops).

If the project uses multiple registries, ask which packages go to each one.
Do not replace the default registry merely to authenticate one package scope.

## 3. Create a dedicated PAT

In the **Azure DevOps website**, not the Azure Portal:

1. Open **User settings → Personal access tokens** and select **New Token**.
2. Give it a descriptive purpose, such as `Local npm package access`.
3. Select the intended organisation and the shortest practical expiry allowed
   by your team.
4. Select only the permissions needed for your task.

For package consumption, use **Packaging: Read**. Publishing requires write
permission; do not grant it simply to install dependencies. Microsoft's general
npm connection example requests read/write, so distinguish that broader example
from your actual needs. See the [Packaging scope definitions](https://github.com/MicrosoftDocs/azure-devops-docs/blob/main/docs/integrate/includes/scopes.md).

A PAT cannot grant access its owner lacks. Ask a feed administrator if your
account cannot read the packages. Saving new upstream packages also requires
the appropriate feed role; see [feed permissions](https://learn.microsoft.com/en-us/azure/devops/artifacts/feeds/feed-permissions?view=azure-devops).

Save the token in your approved password manager if team policy permits it.
Its value is shown only when created. Never share it in chat, tickets,
screenshots, or documentation. See [PAT guidance](https://learn.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops).

## 4. Encode the PAT locally

This method expects a Base64-encoded PAT in `_password` entries.
**Base64 is not encryption. Treat the encoded value exactly like the token.**

The macOS command below prompts without displaying input, encodes it as one
line, and copies the result to the clipboard. The literal token is not part of
the command saved in shell history. The command runs in a separate clean zsh
process; the variable is not exported or left in your interactive shell.

Consider clipboard history and cross-device syncing before continuing. If your
organisation prohibits secrets on the clipboard, use its approved credential
workflow instead. Do not run this while screen sharing or recording.

Paste the command into Terminal:

```sh
/bin/zsh -f -c '
  set -o pipefail
  read -r -s "npm_pat?Paste your Azure DevOps PAT, then press Return: " || exit 1
  printf "\n"
  if [[ -z "$npm_pat" ]]; then
    printf "No token entered; nothing copied.\n" >&2
    exit 1
  fi
  printf "%s" "$npm_pat" |
    /usr/bin/base64 |
    /usr/bin/tr -d "\r\n" |
    /usr/bin/pbcopy || exit 1
  unset npm_pat
  printf "Encoded credential copied. Treat the clipboard as secret.\n"
'
```

Paste the PAT **at the prompt**, not into the command. Nothing appears while
you enter it; that is expected. Do not use an online Base64 encoder.
If the command fails or is cancelled, do not assume the clipboard contains a
new value; resolve the failure and retry before editing credentials.

## 5. Update your user .npmrc

Open the path returned by `npm config get userconfig` in a local plain-text
editor. If the file does not exist, create a plain-text file at that exact path,
not a `.txt` or rich-text file. Do not use `sudo` for your user configuration.

Copy the **user-level authentication block** from the feed instructions,
preserving its URL prefixes and accompanying fields. Replace each relevant
`_password` placeholder with the encoded clipboard value.

- The field is **`_password`**, including the underscore, not `password`.
- Credentials must stay scoped to the correct registry host and path.
- Microsoft's example includes `/npm/registry/` and `/npm/` entries; update
  both matching placeholders.
- Keep the encoded value on one line and preserve unrelated feed settings.
- Do not put this block in the project repository.

A separate `npm login` is not required for this configuration method.

After saving, restrict the file's permissions. If its confirmed location is the
usual `~/.npmrc`, run:

```sh
chmod 600 "$HOME/.npmrc"
```

For a custom location, substitute the actual path. This grants read/write access
only to the file owner; it is not encryption. Do not change an unrelated file.

Clear the current clipboard after pasting:

```sh
printf '' | /usr/bin/pbcopy
```

This does **not** erase copies retained by clipboard managers or other devices.
Keep editor backups, swap files, and cloud syncing in mind: they can retain
credentials too. Follow your organisation's secret-storage policy.

### If you use chezmoi

Keep credential-bearing `.npmrc` content out of plaintext chezmoi source, Git
(including private repositories), and exported configuration bundles. Review
ownership before editing an already managed file. See the
[chezmoi learning path](chezmoi.md#ownership-templates-and-secrets).

Chezmoi may manage a credential-free template, but secret retrieval/rendering
needs a separately reviewed design. Marking a file `private` changes permissions;
it does not encrypt content. If a token has already entered source history,
revoke it; merely removing the current file does not remove that exposure.

## 6. Verify access from your project

Open Terminal in the project directory. Inspect configuration and routing:

```sh
npm config get userconfig
npm config get registry
```

For a scoped package, also inspect its mapping:

```sh
npm config get @YOUR_SCOPE:registry
```

Replace `YOUR_SCOPE` with the real scope. Skip this check for an unscoped
configuration. An unset scope mapping means npm falls back to the default
registry; compare that with the project's intended routing.

Request metadata for a package genuinely private to your feed:

```sh
npm view "@YOUR_SCOPE/YOUR_PRIVATE_PACKAGE" version \
  --registry="YOUR_EXACT_FEED_URL" \
  --prefer-online
```

Replace all placeholders; for an unscoped package use its plain name instead.
Choose a known version explicitly as `package@version` if it has no `latest` tag.
**Expected result:** a package version without an authentication error.
[`npm view`](https://docs.npmjs.com/cli/v11/commands/npm-view/) retrieves metadata;
it does not install the package.

Check the project's normal routing without the override:

```sh
npm view "@YOUR_SCOPE/YOUR_PRIVATE_PACKAGE" version --prefer-online
```

Once both checks succeed, follow the project's normal dependency-installation
instructions. That operation changes the project environment and can execute
package scripts; use a trusted project and its prescribed package manager.

Metadata access does not prove all dependency downloads or publishing work.
Testing only a public package does not establish private-feed access. Record
success/failure without recording the token or credential block.

## Replace an expired or expiring token

You normally do **not** need to recreate either `.npmrc` file.

1. Create a replacement with the intended organisation and permissions.
2. Encode it locally and replace only the matching user-level credential values.
3. Repeat both private-package checks.
4. Revoke the old token after updating any other legitimate consumers.

**Regenerate** invalidates the previous token value. Do not regenerate a token
used by other tools without accounting for them. For an expired or revoked PAT,
create a new one. If a token leaks, revoke it immediately rather than waiting
for planned rotation.

## Troubleshooting

| Symptom | What to check |
|---|---|
| `401` or authentication error | Expiry/revocation, encoding, and exact credential URL prefixes |
| `403` or access denied | Account access, PAT scopes, and feed permissions |
| Package not found | Feed URL, package name/version, and access restrictions |
| Explicit-registry check succeeds; normal check fails | Project routing and package-scope mapping |
| Metadata succeeds; installation fails | Other feeds, lockfile URLs, download-path credentials, and project requirements |
| Edits appear ineffective | `userconfig` overrides, environment variables, working directory, and the actual edited file |
| TLS or certificate error | Approved proxy/certificate setup; do not disable certificate verification |

These are starting points, not a one-to-one diagnosis from an error code.
`npm config ls -l` can inspect configuration but is not an authentication test.
Do not post complete configuration files or unreviewed diagnostic output.

## Other environments

- **Windows:** follow Microsoft's Windows-specific feed instructions.
- **pnpm or Yarn:** use the project's version-specific instructions; this guide
  verifies npm, not every package manager.
- **Azure Pipelines:** use a build authentication workflow such as
  [`npmAuthenticate@0`](https://learn.microsoft.com/en-us/azure/devops/pipelines/tasks/reference/npm-authenticate-v0?view=azure-pipelines)
  with appropriate feed permissions, rather than copying a developer's file.
- **Containers:** do not bake a developer's credential file into an image.
- **Approved credential tooling:** follow employer policy; this guide is not
  authority to bypass it.
