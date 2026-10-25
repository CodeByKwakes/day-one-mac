# Documentation website implementation plan

> For agentic workers: implement the approved work inline with the executing-plans
> skill, then obtain one independent review. Do not commit, push or publish without
> the user's corresponding instruction.

**Goal:** Open Day One Mac documentation through a readable, responsive website
or a complete offline download, without installing a runtime.

**Architecture:** Reuse the static reader and reviewed documentation inventory.
A contributor build produces a website and matching offline ZIP. A documentation
workflow deploys the validated main-branch revision to GitHub Pages. AI skills
continue reading their bundled guides independently.

**Tech stack:** Node.js 22.20+, static HTML/CSS/JavaScript, Markdown-it, ZIP,
GitHub Actions and GitHub Pages.

**Spec:** User-approved proposal in this chat: hosted documentation, an offline
download, updated README/skill guidance and optional convenient opening, with
Impeccable-led readability and responsive design.

## Constraints and direction

- Preserve the existing teal identity and documentation navigation. Read mode;
  system fonts, comfortable line lengths, light/dark system preference, no remote
  fonts, analytics, tracking, setup execution or new client dependency.
- Preserve documented routes, anchors, copy/print behavior and offline use.
- Keep executable recipes in canonical manual guides. Public inventories remain
  the only export inputs; private files and symlinks are excluded.
- Preserve earlier uncommitted VS Code and instruction-file changes.
- The Impeccable context launcher is unavailable. Inspect the existing reader
  directly and use its refinement/adaptation playbooks. No replacement identity
  or additional visual-direction approval is needed for this refinement.
- Implement convenient opening with bookmarks and native browser shortcuts;
  a new app is optional and unnecessary for opening a static website.

## Review focus

- The site must work below a project URL prefix and through file URLs.
- The downloaded ZIP must match the site's revision and open without a server.
- Downloads must never include private notes, Git metadata or dependency trees.
- Mobile menus, long code/tables, keyboard navigation and print must remain usable.
- A failed validation, pull request or older commit must not deploy to production.

## Tasks

1. [x] Build and provenance: extend `tools/export-docs.cjs`; add
   `tools/build-docs-site.cjs` and `tests/integration/test-docs-site.cjs`.
   Preserve existing exporter arguments. Verify ZIP contents, matching content
   fingerprints, revision validation, source independence and no-overwrite behavior.
2. [x] Reader: refine `tools/docs/docs-browser.{html,css,js}` and update the
   existing DOM fixture. Verify route links, search, navigation, responsive menu,
   download state, readable code/tables, dark mode and print.
3. [x] Publishing and guidance: add `.github/workflows/docs.yml`, a build script
   entry and contributor instructions. Update the owning reading guide, README
   and umbrella skill; regenerate packages. Publish only after the Validate
   workflow succeeds for the current main revision, with pinned actions and
   minimal deployment permissions.
4. [x] Acceptance: run lint, static and integration gates, actionlint, pinned
   Skills CLI acceptance, HTTP/file browser checks and two bounded visual passes
   at most. Obtain an independent final review. Open a local preview for the user.

## Evidence

Baseline: `ca4a78e`; current branch contains earlier approved, uncommitted changes.
Before-edit screenshots are outside the repository. The existing reader is
functional, but metadata crowds the header, mobile tables become cramped and
the current build provides no ready-made download or publishing workflow.

Acceptance: full repository validation and actionlint passed. The pinned Skills
CLI passed 48 isolated installations plus shared-client, Git-source, update and
removal cases. Browser checks covered HTTP project-prefix routes, extracted
file URLs, download identity, search, errors, print and widths 320–1920px.
Two visual passes covered desktop, mobile touch, tablet, dark mode and the
923px in-app viewport. Text contrast passed 4.5:1 and control/focus contrast
passed 3:1. An independent final review found no material issues and verified
that every exported source matches the offline ZIP byte-for-byte.

Convenient opening uses a bookmark or native Internet location file. No extra
app was added. Source changes remain uncommitted; GitHub Pages configuration
and public deployment have not been performed. Existing approved profile and
instruction-file edits remain intact.
