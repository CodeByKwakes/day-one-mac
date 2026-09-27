[← Maintainer material](README.md) · [Acceptance procedure](ACCEPTANCE.md)

# Candidate notes: executable modules and acceptance hardening

These are **draft review notes**, not a published release or a replacement for
the Release Please changelog. Select the final version through the normal
release process after reviewing evidence for the intended commit.

## User-visible changes

- Every listed Optional/Advanced module now has a bounded executable scope
  through plan/apply/check/resume. This does not automate its entire checklist.
- Module 18 reviews explicitly selected Git identities, signing configuration
  and worktree layout, and generates configuration proposals without applying
  them. Provider authentication and real signing verification remain manual.
- Module 20 stages explicitly checksummed regular files from a reviewed mounted
  backup into fresh private directories. Saved intent supports safe retries;
  changed sources/destinations stop rather than being overwritten. It also
  supports an explicit no-restore decision.
- Artifact source validation resolves the installed runtime's versioned code
  directory physically. The supported `current` launcher symlink no longer
  causes bundled helper/artifact sources to be rejected as unsafe inputs.
  User-supplied data symlinks are still rejected.

## Maintainer changes

- Packaged acceptance exercises the release archive through its installed
  launcher, including Node helpers, drift, audit and manual-completion limits.
  It is part of the existing Validate workflow.
- An opt-in native rehearsal uses only a disposable APFS image, retains private
  evidence and verifies detach. It cannot target an existing disk or backup.
- Release-readiness reports separate automated gates, native coverage, source
  cleanliness, stable inputs and manual approval. No publishing or automatic
  dependency installation is included.

## Compatibility and limits

- Existing guide commands and saved state formats remain supported. There is
  no state migration, forced configuration replacement or automatic cleanup.
- Node 22+ must already be available for the relevant helper modules and
  contributor acceptance tooling. The runtime ships no `node_modules`.
- Restore staging preserves bytes, not ACLs, extended attributes, ownership or
  executable bits. It is not live migration, archive extraction, a database
  import, a secret scanner or proof that the original backup was correct.
- Automated fixtures use synthetic completion markers. A native APFS test
  does not replace a fresh-user eight-phase setup or real-provider verification.
- Signing/trust decisions, credential handling, application imports, live
  promotion, GUI/security changes and destructive lifecycle operations remain
  deliberately manual.

## Evidence required before publication

Use [the acceptance procedure](ACCEPTANCE.md). Capture the exact candidate
archive hash, tested commit and report directory; resolve failed/skipped gates
and complete the human checklist. Do not copy a successful result from another
commit or treat these draft notes as evidence that testing happened.
