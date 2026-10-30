# Separate the personal toolkit from Day One Mac

Approved after the product-versus-contributor skill review. Keep the public
`day-one-mac` entry point and its bundled workflows. Keep only
`day-one-mac-maintenance` as a checkout-local contributor skill.

## Tasks and decisions

- [x] Inspect personal copies and preserve the pending workspace/app changes.
- [x] Copy and verify all eleven general helpers into a recoverable personal library.
- [x] Enable eight general helpers and retain three specialists outside discovery.
- [x] Remove the verified repository copies and their Claude aliases.
- [x] Add clear product/maintenance display labels and update contributor guidance.
- [x] Verify personal links, repository boundaries, packages and regression gates.

Ruling: keep codebase design, planning, execution, debugging, verification,
general review, technical writing and Impeccable active in the personal toolkit.
Retain documentation-writer, design-taste-frontend and differential-review as
optional library entries. Do not delete other projects' local writing skills.

Ruling: preserve existing standalone Day One Mac installations and client
visibility settings. Native plugin refresh is separate from repository cleanup;
do not deploy the unrelated workspace/app changes through an artifact rebuild.

Ruling: preserve the working tree's pending workspace/app work. Keep recovery
copies and the initial diff outside the repository. Avoid a combined commit of
unrelated changes or recording machine-specific paths in public sources.

Ruling: preserve upstream skill provenance in the private library and recovery
copy, then clear the repository lock entries. Restoring project skills must not
recreate the personal toolkit. Keep a regression assertion for that boundary.

## Verification

Personal library: all eleven skill manifests validate, eight active Claude
aliases resolve to the shared personal sources, and three optional entries are
absent from discovery roots. Original hashes and upstream provenance survive in
private recovery/library copies. Other projects' local writing skills were not
changed. Personal copies carry portable fallbacks and distinct Codex UI labels.

Repository: the final full gate, actionlint, independent-package checks and
66 pinned Skills CLI installation cases pass. The actual pinned lockfile restore
command performs no installation with the empty repository lock. The native
plugin fixture passes with Codex and Claude; a per-process marketplace name avoids
colliding with an already-installed plugin. An independent reviewer reported the
stale lockfile, verified its fix, and found no remaining issues.

Thirteen pre-existing source files retain their initial hashes. Both source
inventories contain only the intended metadata append beyond their initial
contents. Existing generated-package workspace/app changes remain in the working
tree alongside the regeneration from this cleanup. No installed plugin artifact
was refreshed and no commit combined the pending work with this consolidation.
