# Documentation route rewrite acceptance

Date: 24 October 2026. Scope: the approved Phase 2 documentation rewrite on top
of `00167b5` and the pre-existing profile/shell work. This is source-tree and
isolated-package evidence, not evidence of a published release or a live Mac
reconfiguration.

## Result

User procedures now have two route owners: `docs/setup/assisted` and
`docs/setup/manual`. Common prerequisites, choices, terminology, acceptance
criteria and reference data live in `docs/shared`. The indexes, CLI topics,
setup menu, offline reader and generated Raycast guide links use those owners.

There are 49 canonical assisted guides, 80 canonical manual guides and 17 shared
pages, plus the two documentation entry pages. The 218 compatibility guides
remain regular packaged files. A retained pre-rewrite heading fixture covers
234 original paths and 3,229 headings; split-topic checks exercise the VS Code,
database, shell, MCP and local-HTTPS destinations explicitly.

The manual VS Code task contains the four profile extension tables and links
to generated settings from the existing profile catalogue. Its assisted
counterpart owns generation, replacement and restore. Manual shell, AI, database
and Second Brain tasks no longer require Day One Mac helper commands.

## Verification

| Check | Result |
|---|---|
| `pnpm run lint` | Passed: ShellCheck on 228 scripts and Markdown lint |
| `pnpm run validate:static` | Passed: local paths/fragments, catalogue ownership, runtime inventory and generated reference |
| `tools/validate.sh --all` | Passed: full static and integration gate, including all 96 base selection plans |
| Documentation route contract | Passed: original paths/headings, split-topic owners, manual command boundaries and isolated Warp startup |
| Offline export and reader fixtures | Passed: HTML/Markdown links, anchors, navigation, search, privacy, no-overwrite and symlink rejection |
| Packaged module acceptance | Passed on the final candidate: all 14 active capabilities and packaged helpers |
| Isolated runtime upgrade and rollback | Passed from the prior committed tree to the packaged candidate and back; recorded state, ownership and shell files preserved |
| Generated Raycast guide destinations | Passed: every generated Markdown target exists and is canonical |
| `git diff --check` | Passed |

The initial restricted integration run could not create a temporary Unix socket.
The authorized full rerun allowed that fixture and passed without skipping it.
Homebrew pnpm could not verify the selected package-manager release through the
restricted network; the already available bundled pnpm ran the same scripts
against existing dependencies. Package-manager and dependency files were not
changed for that workaround.

After the full gate, the final guide-path corrections were checked again by the
packaged acceptance, upgrade/rollback, route, Raycast, Markdown and changed-shell
checks. No live runtime, profile, shell configuration, account or credential was
changed by this rewrite.

## Independent review

The fresh-context reviewer found five Important issues and no Critical issues.
All five were corrected:

1. Kept `compinit` inside the non-Warp guard; the documented snippet first failed
   in an isolated test home, then passed after correction.
2. Removed assisted profile/client prerequisites and the Zsh/editor prerequisite
   cycle from manual tasks.
3. Preserved 36 entry-page headings and the root README's existing start anchor.
4. Routed split VS Code and local-HTTPS fragments to the actual task owner.
5. Restored macOS permission, login-item, browser-role and menu-bar guidance under
   the manual macOS task.

The earlier profile configuration, replacement implementation, phase code,
shell template, public dispatcher and skill lock match the pre-turn baseline.
Second Brain payload assets and historical maintainer records retain their
contents. The historical new-device blueprint was relocated, with navigation
rebased and its historical status stated.

## Evidence limits and deferred work

- The runtime guard accepts native Apple-silicon macOS major versions 15-27;
  that does not establish hardware or managed-device acceptance for every build.
- Vendor accounts, GUI permissions, production database access, backup recovery
  and organisation-specific policies still require the documented human checks.
- This source was not published. Installed help and release provenance remain
  the authority for available commands; the local `v1.5.0` tag predates the
  `vscode-profile` command documented in current source.
- Existing source-verification dates were retained where material was moved.
  External documentation was not treated as a live account or hardware test.
- The two contributor-skill reference repairs identified in Phase 1 remain a
  separate task, as approved.
