# Readiness fixes implementation plan

> For agentic workers: execute the approved fixes task by task with the
> repository gates. Record isolated checks separately from live acceptance.

**Goal:** Resolve the confirmed documentation and contributor-check failures
without claiming clean-device or live-account acceptance.

**Architecture:** Manual configuration backups use the existing terminal guide.
Third-party contributor tools remain local dependencies, separate from owned
skills and public packages. Edit canonical guides and regenerate packages.

**Tech stack:** macOS Bash 3.2, Zsh, Node.js, pnpm and Markdown.

**Spec:** The user-approved repository readiness review: unsafe fixed-name
backups, gstack ownership/lint failures, no-Node installation verification,
stale OmniRoute assumptions and navigation, and missing device evidence.

## Constraints and review focus

- Preserve existing recovery copies and the requested repo-local gstack install.
- Do not change live Mac configuration, publish, push or invent acceptance.
- Keep manual recipes independent of project helpers.
- Exercise repeated backups, absent files, spaces/Unicode, copy failures and
  private permissions; reject unsupported targets before editing.
- Verify both dependency-present and dependency-absent contributor layouts.
- Keep no-Node copy verification separate from Skills CLI lifecycle commands.

## Tasks

- [x] Add a regression fixture for the actual configuration-backup recipe;
  confirm the old recipe fails, fix it, then route all three affected recipes
  through `docs/shared/terminal-basics.md` and rerun the fixture.
- [x] Update `tests/integration/test-ai-components.cjs`, `tools/lint.sh`,
  `.gitignore` and contributor ownership documentation for optional local gstack.
  Test the lint boundary with a synthetic third-party tree and owned scripts.
- [x] Correct the manual skill-copy lifecycle, selected OmniRoute routes,
  troubleshooting/index links, ShellCheck explanations and validation summary.
- [x] Expand `maintainers/acceptance/CURRENT-READINESS.md` with a private pilot
  matrix and an ordered spare-Mac procedure. Leave live results untested.
- [x] Regenerate docs, agent adapters and skill packages. Run the complete gate,
  pinned Skills CLI acceptance and native-client artifact validation.
- [x] Review the final diff and report local results and remaining live checks.

## Execution record

The baseline is the committed AGENTS router plus the user-requested gstack
installation and lockfile change. These fixes do not include a commit or push.

Kind: runbook. Audience: contributors implementing the approved review fixes.
Purpose: complete and verify those fixes. Non-goals: live provisioning,
publication, and optional capability certification.

Confirmed results: Bash/Zsh backup and no-Node copy fixtures pass; local gstack
ownership and lint-boundary fixtures pass. All 16 owned shell scripts pass with
ShellCheck suppressions removed. Public paths and anchors pass static checks.

The dependency-absent contributor layout also passed ownership and lint-boundary
checks in an isolated copy containing only the owned skill and its Claude link.

Validation: `pnpm run validate:complete` passed with native client executables
supplied. Skills CLI 1.7.4 acceptance passed 66 isolated installations plus
combined-client links, local-Git sources and scoped updates. No live provider,
clean-device or publication check was performed.

Ruling: keep gstack as an optional ignored repo-local dependency with a reviewed
lock entry. Preserve Codex-only scope and require no toolkit in CI.

Durable findings: test macOS paths using resolved paths on both sides because
`/var` and `/private/var` may name the same fixture. Lint the owned shell sources
without inherited suppressions before retaining historical exemptions.

Independent review found one minor mismatch in the lint script's suppression
instructions; its help and failure messages now match the inline-only policy.
The reviewer found no other actionable issues and confirmed the historical
readiness plan is unchanged. Live provider access, client discovery and
clean-device acceptance remain unverified.
