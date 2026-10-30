# MCP distribution preparation

Goal: prepare a reusable MCP package and local versioned Docker artifacts without
publishing, pushing, registering clients or changing live Mac preferences.

## Scope and interfaces

- Keep the optional server under `integrations/mcp` and preserve other ongoing edits.
- Package compiled code, bundled guides, licence, README and a production
  shrinkwrap. Exclude tests, private files and dependency directories.
- Add `day-one-mac-mcp` and `day-one-mac-mcp-configure` executable entries.
- Configuration generation prints Claude, Codex, VS Code and Raycast settings.
  Direct mode uses the installed package; npm mode pins the package version and
  resolves Node/npm paths per machine; Docker mode resolves the local launcher.
- Build local versioned Docker tags and export an image archive for transfer.
- Keep approval, preview, drift, lock and recovery behaviour unchanged.

## Verification

- [x] Build and run the server safety tests.
- [x] Pack, inspect and install a tarball in a temporary directory with spaces.
- [x] Verify installed binaries, discovery and guide reads outside the checkout.
- [x] Verify generated configurations, bad arguments and executable discovery.
- [x] Build and smoke-test the versioned image; create local transfer artifacts.
- [x] Run repository checks and pinned Skills CLI acceptance; obtain a final review.

No registry credentials, release secrets, upload steps or publication workflows
are part of this change. Package-name ownership remains a publication prerequisite.

## Verification evidence

- Native and Linux image builds pass 22 tests covering server safety, executable
  discovery, npm fallback paths, configuration arguments and local image export
  checksums, failure cleanup and no-overwrite behaviour.
- The real tarball installs with production dependencies only in an isolated
  Unicode path with spaces. Both executables and stdio discovery work without
  the source checkout. A minimal GUI-like environment launches the local tarball
  through the generated npm command structure.
- Generated Codex TOML parses and agrees with JSON output in direct, npm and
  Docker modes. The final arm64 image passes its read-only stdio smoke test.
- Full repository validation, actionlint and whitespace checks pass. Pinned
  Skills CLI acceptance passes 66 isolated installs and scoped lifecycle checks.
- A fresh distribution review found no material blockers. Its coverage gaps for
  Docker discovery, export failures, checksum/no-overwrite behaviour and minimal
  npm launch environments are covered by tests and the TOML parsing check.
- The initial transfer command exposed npm pack ignoring --prefix. The incorrect
  local contributor archive was removed. The artifact helper now fixes cwd,
  verifies package identity and rejects unexpected packed files before checksums.
- Final local outputs include the npm tarball, arm64 Docker archive, SHA-256
  files and a manifest. Artifact destinations are newly reserved and ignored.
  No registry upload, push, client registration or live preference change ran.

## Distribution decision

The npm shrinkwrap retains contributor dependency metadata so a source checkout
can run npm ci. Installed consumers omit development dependencies, as verified
by the package acceptance test. Package-name ownership remains a prerequisite
for a separately approved registry publication.
