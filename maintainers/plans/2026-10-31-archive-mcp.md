# Archive the Day One Mac MCP

Approved scope: archive the server in the repository and disable its selected
connections on this Mac, preserving skills, manual guides and recovery evidence.

Kind: runbook/reference | Audience: contributors and existing installations |
Purpose: pause the integration reversibly | Non-goals: remove external MCPs,
change applications, activate agents, publish, commit or push.

## Implementation

- Preserve tracked MCP source and related build/configuration snapshots under a
  dated contributor archive, with original paths and SHA-256 evidence.
- Keep the original README URL as a portable archive notice. Remove the active
  specification from source inventories and server/container steps from CI.
- Make native plugin packages skill-only with independent version 0.1.2. Keep
  portable skills and reviewed helpers independent of any server.
- Disable existing selected client connections with private configuration
  backups. Retain older plugin artifacts and standalone skill copies.
- Verify archive hashes, artifact relocation, current client flags, repository
  gates and pinned Skills CLI lifecycle acceptance. Existing sessions may need
  refresh; do not infer skill invocation from a configuration flag alone.

Archived implementation files remain historical and are not rewritten to follow
current paths or API versions. Restoring them requires a new compatibility review.

## Verification evidence

- Full `pnpm run validate:complete` passed, including lint, static/reference
  checks, macOS integration fixtures, skill-only plugin fixtures and actionlint.
- Optional native Claude validation and Codex marketplace discovery passed with
  approved installed executables and isolated test configuration.
- Skills CLI 1.7.4 passed 66 isolated installations for 11 skills, three clients
  and two scopes, plus combined-client, Git-source and scoped update cases.
- Archive hashes matched preserved files. Current builds have no MCP manifest,
  compiled server or dependency on the archived SDK tree.
- Local Codex policy reports this server disabled while its plugin stays enabled.
  Claude's user-scoped server-bearing plugin is disabled and the existing
  standalone skill remains available. Private configuration and build-cache
  recovery copies were retained outside the repository.

Live account-backed invocation of the new skill-only plugin version is not
claimed. The installed older package was disabled at its server boundary rather
than automatically replaced. No commit, push, publication or unrelated server
change was performed.
