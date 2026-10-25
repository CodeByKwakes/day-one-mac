# Inspect Second Brain repository connections

`helpers/second-brain/inspect.cjs` checks a private connection file and selected
local Git checkouts. It prints JSON metadata and file hashes, never file bodies.
It makes no network requests or filesystem writes and does not launch an AI client.
Manual connections use the [owning guide](../../setup/manual/second-brain/repositories.md).

## Run the optional check

You need Node.js 22.20+ and Git on PATH. Git must support `--no-lazy-fetch`;
the checker fails without it. From an installed Second Brain or umbrella skill
directory, inspect the source and help first:

```bash
node references/project/helpers/second-brain/inspect.cjs --help
node references/project/helpers/second-brain/inspect.cjs \
  --connections "$HOME/Private Setup/second-brain/repositories.json" \
  --repo sample-api
```

Replace the example path and ID with your selected private file and record.
A contributor uses `node helpers/second-brain/inspect.cjs` from the source root.
Do not put private records inside either the source checkout or installed package.
No application installation, authentication or note repair happens during this check.

| Option | Default | Use |
|---|---|---|
| `--connections FILE` | Required | Regular JSON connection file, outside the source/package, vault and selected code checkout |
| `--repo ID` | All records | Check one explicit registered ID; an unknown ID fails |
| `--help`, `-h` | Off | Print usage without reading a connection file |

## Connection fields

Use the public [placeholder example](../../../config/second-brain/repositories.example.json)
as a starting point. Replace placeholders privately before running the check.
Unknown fields are rejected so misspellings cannot silently widen access.

| Field | Default | Use |
|---|---|---|
| `schema` | Required: `1` | Format version |
| `vault` | Absent for Notion-only records | Absolute existing directory; required for `projectNote` records |
| `repositories` | Required array | Up to 32 records; an empty list represents no connections |
| `id` | Required | Unique lowercase ID, starting with a letter; letters, digits and hyphens, up to 64 characters |
| `checkout` | Required | Absolute path to an existing Git checkout root or worktree |
| `projectNote` | No default | Relative `.md` destination under `vault`; may not exist yet |
| `projectPage` | No default | Alternative Notion HTTPS page URL, without credentials or query parameters; exactly one destination field is required |
| `aiAccess` | `link-only` | `link-only` or `selected-files`; this records intent, not OS permissions |
| `readPaths` | Required array | Empty for link-only; 1-64 exact relative files or directory prefixes for selected-files |

Paths support spaces and Unicode. Use actual absolute paths; JSON does not expand
shell variables. Relative paths reject traversal, control characters, backslashes
and glob syntax. Symlinks within selected source or destination paths are refused.
An explicitly chosen root is resolved to its real location before checking overlap.

## Selection and evidence

Link-only records check the checkout root and destination path without enumerating
source files. Selected-files records require an existing HEAD commit. Inspection
lists tracked entries under the selected paths, then reads eligible regular UTF-8
text locally to produce SHA-256 fingerprints. It does not print content.

Excluded paths include `.env` variants, credential/key files, Git and client
configuration directories, dependency/build trees, exports and backups.
Submodules, symlinks, unsupported extensions, binary data and oversized files are
skipped. The supported text extensions are explicit in the helper source.
These filters do not detect every secret; inspect the selection before sharing it.

Limits are 64 KiB for the connection file, 2,000 selected index entries and
2,000 selected HEAD entries per repository, 512 KiB per text file and 8 MiB of
eligible text per repository.
Git commands have a 15-second timeout and 4 MiB output limit. A limit failure
requires a narrower selection, not a broader permission setting.

The checker compares raw local bytes and executable modes with the Git index and
HEAD metadata. It does not use `git status`, content filters, text converters or
external diffs. This detects edits even when `assume-unchanged` or `skip-worktree`
flags hide them from ordinary Git status. Line-ending conversion and other content
normalization can produce `selected-files-changed` even when ordinary Git status
looks clean: the inspected bytes differ from the stored object.

Untracked files are excluded. Skipped files are not certified clean; eligible
missing files and removed index entries can mark a selection changed. A clean
result describes only the eligible inspected files, not the whole repository.
Optional index locks and filesystem monitor hooks are disabled. Git replacement
objects, transport protocols and lazy fetching are also disabled. Missing local
objects produce a finding, including in partial clones; the check never fetches
them. See the [Git command reference](https://git-scm.com/docs/git) for these
controls.

## Report fields and exit status

| Field | Use |
|---|---|
| `schema` | Report version, currently `1` |
| `ok` | Whether all selected records passed validation |
| `repositories` | Per-record results; only the requested ID when filtered |
| `findings` | Top-level input problems; per-record problems appear in that record's `findings` |
| Record `id`, `aiAccess`, `checkout` | Identity, intended mode and resolved root; root is null if unavailable |
| Record `projectNote` or `projectPage` | Validated destination; omitted if validation stopped earlier |
| Record `revision` | Observed HEAD, or null for link-only/unavailable inspection |
| Record `workingTree` | `not-inspected`, `selected-files-clean` or `selected-files-changed` |
| Record `files` | Eligible `{path, bytes, sha256}` entries; cleared if that record fails |
| Record `skipped` | `{path, reason}` entries excluded from content inspection |
| Finding `code`, `message` | Bounded explanation without raw Git output or file bodies |

Exit `0` means the selected connections are valid, including an empty list. Exit
`1` means invalid or unavailable input. Exit `2` means incorrect command arguments.
Skipped paths do not make an otherwise useful selection fail. An entirely skipped
selection fails because it supplies no eligible evidence.

The report is private: it can contain local paths and a selected Notion page URL.
Keep it outside public issues and repositories. It does not certify account policy,
backup health or model behavior, and it does not enforce what the AI client can read.

## Failure handling and recovery

On a failure, leave source files unchanged and review the finding. Correct the
private connection file from its backup or select a narrower scope. Do not initialize
Git, create a commit, install tools or enable network access as an automatic repair.

Stop concurrent edits before inspection. Detected file or HEAD changes fail the
check, but the report is not an atomic repository snapshot or a security boundary
against concurrent filesystem replacement. Recheck selected evidence before using
it for a note. Source hashes describe the bytes inspected at that time.
