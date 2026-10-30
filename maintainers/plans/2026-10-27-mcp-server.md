# Optional MCP server implementation plan

**Goal:** Build the requested optional MCP server without restoring a setup runner.
**Architecture:** A stdio server packages selected canonical guides, exposes bounded
read-only checks and offers one opt-in desktop-click preference operation.
**Stack:** TypeScript, official MCP SDK, Zod, Node.js 22.20+.
**Spec:** The five-part MCP server request in this chat. This plan is a runbook for
contributors implementing and verifying that request.

## Constraints and interfaces

- Keep the server under `integrations/mcp`; no global CLI or background service.
- Four tools: `list_guides`, `read_guide`, `check_host`, `desktop_click`.
- Eight static resources: the catalogue and seven allowlisted guides.
- Two prompts: `setup_plan` and `troubleshoot_setup`.
- `desktop_click` previews by default. Application requires native Apple silicon,
  startup opt-in, a private backup directory, an unexpired single-use preview
  token, exact confirmation and an unchanged original value.
- Containers serve guides only; no host mounts, host execution bridge or socket.
- Do not register clients, change live preferences, commit or publish in this task.

## Tasks and verification

- [x] Add a pinned package, build configuration and reviewed guide bundler.
- [x] Test then implement schemas, discovery, resource reads and prompts.
- [x] Test then implement desktop-click preview, confirmation, expiry, replay,
  cross-process lock, drift, private backups, verification and failure reporting.
- [x] Test a real stdio client and Linux/read-only behaviour.
- [x] Add native/Docker installation, all four client examples, recovery and
  troubleshooting. Run the server tests and repository checks.
- [x] Obtain a fresh review and address material findings before delivery.

## Review focus

Reject unknown keys and guide IDs; never read an arbitrary path. Confirmation
must bind to the exact preview and expire. Missing or non-boolean preferences
must not be confused with command errors. Concurrent clients must share a lock.
Failed writes retain recovery evidence and never claim successful application.

## Decisions

- The request explicitly authorizes an optional server and a bounded mutation.
  Existing recipes stay canonical; Homebrew, shell, Git and application changes
  remain guided operations outside this server.
- The requested build proceeds in this chat without an extra planning approval.
  The final review is delegated as required by the execution skill.

## Verification evidence

- Native TypeScript build and 16 tests pass. Mutation tests use simulated host
  writes and temporary directories. A live native smoke check read platform,
  macOS version and a desktop preference preview without applying it.
- Docker build runs the same 16 tests on Linux. The final non-root, read-only
  image passes stdio discovery and rejects macOS preference operations.
- The full repository gate, actionlint and diff whitespace check pass. Pinned
  Skills CLI acceptance passes 66 isolated installations and scoped lifecycle
  checks. No live provider/account acceptance or client registration is claimed.
- A fresh reviewer found a backup-directory-dependent lock. The regression failed
  before the fix and passed with a fixed per-user lock. Native preference adapter
  error cases, default preview behaviour and extra prompt arguments are covered.
  CI also builds and smoke-tests the final container image.
- The Markdown gate initially linted nested dependency READMEs. Recursive
  dependency exclusion resolves that failure without weakening source checks.
- No Mac preference was applied, no live client was registered, and no commit or
  remote publication was performed. No review finding remains deferred.
