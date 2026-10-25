# Restructure differential security review — 19 October 2026

## Executive summary

**Baseline:** `0dcfeca`. **Candidate:** uncommitted restructure on `codex/optional-tool-docs`.
**Recommendation at initial review:** conditional; address the four findings below before accepting the restructure.
**Overall change risk:** high because executable locations, packaging and completion evidence are changing. The observed defects concern failure handling and availability; this review did not establish a remote exploit or credential disclosure.

| Severity | Count |
| --- | ---: |
| Critical | 0 |
| High / P1 | 1 |
| Medium / P2 | 3 |
| Low | 0 |

The existing state-path, atomic-write, runtime inventory, activation and rollback helpers retain their substantive safety checks. The new phase dependency catalogue needs a fail-closed boundary. Ordinary folder commands also have one unresolved source-path error. Findings were communicated to the implementer as they were confirmed; this is the initial-review snapshot, not an assertion that later edits remain defective.

## Review focus

1. An upgrade with existing phase evidence must report affected phases as stale without deleting settings or ownership evidence.
2. Paths with spaces and Unicode, execution outside the checkout and packaged runtime execution must resolve consistently.
3. Old documentation links and script entry points must remain useful after moves.
4. Missing or malformed configuration must fail explicitly, without accepting false completion or installing anything.
5. Documentation, profile generation and preview commands must not mutate the user's Mac.

## What changed and how it was compared

The comparison uses the three manifests under `maintainers/architecture/`: 143 code mappings, 280 documentation/asset mappings and 6 configuration mappings. Each mapped implementation was compared with `git show 0dcfeca:<old-path>` rather than interpreting untracked destination files as absent. These counts describe mapping entries, not unique changed files; some entries are mechanical moves. Ordinary tracked diffs were also inspected for the launcher, installer and runtime allowlist. There are no candidate commits after the baseline at this review point.

Risk-first review concentrated on `src/core/`, `src/runtime/`, setup fingerprinting and extracted setup helpers, the launcher/installer, profile generation, documentation export and reader routing, runtime packaging and compatibility entry points. User-added skill vendor contents were excluded from authored-change assessment.

## Findings

### R1 — High / P1: dependency failure can run a phase and overwrite its completion evidence

**Locations:** `src/setup/installation.sh:77–81`, `src/setup/setup.sh:409–434`; related unchecked nesting at `src/setup/installation.sh:26` and `:73`.

The new `phase_fingerprint` correctly returns failure when `phase-dependencies.tsv` is missing, but `mark_phase_done` embeds that command substitution directly in the arguments to `day_one_write_state`. The writer's success masks the fingerprint failure. The phase implementation has already run by this point. A failed fingerprint therefore produces a blank completion marker and a `PASS phase-02` log entry. This destroys an existing marker rather than retaining it as stale evidence. `phase_done` now rejects blank fingerprints, which prevents that blank marker from satisfying the later optional-module gate; it does not prevent the premature installer call, evidence replacement or success log.

**Reproduction performed:** in a disposable copy of `scripts`, `src` and `config`, source the real setup runner under a temporary HOME/state root, set ordinary fixture choices, create an existing `completed/02` marker, rename `config/catalogs/phase-dependencies.tsv`, replace only `phase_02` with a harmless sentinel, and call the real `run_phase 02`.

Observed result:

```text
INSTALLER CALLED
run_phase returned success; completion bytes: 1
log: … PASS phase-02
awk: can't open file …/config/catalogs/phase-dependencies.tsv
```

The stub establishes call order without installing software. With the real phase, the same branch can reach Homebrew preparation before detecting the missing catalogue.

**Preconditions / adversarial model:** a broken source checkout or malformed release/configuration; no privileged attacker is needed. Someone able to replace the runtime code already has a stronger capability, so this is a fail-closed/evidence-integrity finding, not an independent privilege-escalation claim.

**History:** the marker writer is inherited from the baseline; the new external dependency catalogue introduces this additional ordinary failure input. Baseline fingerprint dependency hashing was hardened in `f597521` (`feat: harden setup and make optional and advanced modules executable (#6)`). The intended dependency checks must be propagated through their callers.

**Fix and targeted tests:** validate all required catalogues before state writes, locks that create state, or phase/installation execution. Capture each fingerprint into a local variable with an explicit status check, require a nonempty valid digest, and only then write the marker. Propagate failures through Installation Centre fingerprints too. Test missing/truncated catalogues through apply/resume using installer sentinels; assert nonzero status, no installer call, no PASS log, and byte-for-byte preservation of prior markers and ownership evidence.

### R2 — Medium / P2: malformed catalogue rows can silently remove phase implementation coverage

**Location:** `src/core/phase-dependencies.sh:7–14`.

The `awk` selection filters rows before validating the catalogue. Nonmatching malformed rows are silently ignored, and any surviving shared row makes the selection nonempty. The parser never requires a phase-specific implementation row. A malformed phase row can therefore produce a successful digest that excludes the phase implementation.

**Reproduction performed:** a temporary catalogue contained these two lines (the first separator is a tab; the second row deliberately has spaces):

```text
*<TAB>src/core/project-paths.sh
02 BROKEN src/setup/phases/02-foundation.sh
```

`day_one_phase_implementation_hash <fixture> 02` returned success. Appending a change to `src/setup/phases/02-foundation.sh` left the digest unchanged. Missing phase rows and extra malformed fields need equivalent rejection tests.

**Impact:** after evidence is recorded against such a catalogue, later changes to omitted implementation files can remain reported current. The same contract serves all eight required phases and the Phase 8 prerequisite for optional modules. This is a local configuration/authoring defect; an attacker with arbitrary runtime write access is outside the integrity protection claimed here.

**Fix and targeted tests:** validate the complete TSV before filtering: exact field count, accepted IDs, safe nonempty paths, duplicate handling, and required phase implementation coverage. Use the phase catalogue's implementation field or an equally explicit coverage invariant. Test malformed separators, omitted phase rows, unknown IDs and duplicate/extra fields, and ensure dependency edits cannot leave a valid stale marker current.

### R3 — Medium / P2: the public folders command sources the old sibling location

**Location:** `src/modules/configure-folders.sh:4`.

The implementation moved from `scripts/` to `src/modules/`, but its `source .../setup.sh` expression is unchanged. Setup now lives in `src/setup/setup.sh`. Consequently all folder actions, including help and read-only plan, fail before argument parsing.

**Reproduction performed:** `scripts/day-one-mac folders --help` returned 1 with `src/modules/setup.sh: No such file or directory`. The public dispatch and the `scripts/configure-folders.sh` compatibility entry point both reach this file.

**History:** the source statement is byte-for-byte unchanged from `0dcfeca:scripts/configure-folders.sh`; its meaning changed with the move.

**Fix and targeted tests:** source `../setup/setup.sh`. Exercise both public and compatibility folder help/plan from an unrelated working directory, from a checkout path with spaces/Unicode and from the packaged runtime. Assert previews preserve the test HOME and state tree.

### R4 — Medium / P2: runtime verification now syntax-checks adapters instead of the moved implementation

**Location:** `src/operations/verify.sh:21–27`.

The verifier still scans `scripts/lib` and `scripts/phases`. Those paths now contain compatibility adapters; Bash syntax checking does not follow their `source` statements. The moved phase and shared-library implementations are therefore no longer checked by the public verifier. Checksum verification proves that packaged bytes match the manifest, not that the shipped shell code parses.

**Reproduction performed:** in a disposable source copy with a `.git` directory, append the invalid syntax `if then` to `src/setup/phases/03-security.sh`, then invoke the real verifier. It returned 0 and printed `Runtime verification passed`. In the baseline the phase implementation occupied the directory traversed by this syntax loop.

**Fix and targeted tests:** check the actual runtime shell implementations under `src/` as well as supported compatibility entry points. Add a fixture that corrupts a relocated phase and one core helper; require nonzero verification. A packaged version of the fixture should regenerate its checksums first, so the test proves syntax coverage rather than merely detecting a checksum mismatch.

## Test coverage and evidence

Executed independently during this review:

- `tests/integration/test-phase-dependencies.sh` — passed; covers unrelated-helper isolation, a changed foundation phase and a missing referenced file, but not malformed/absent catalogue handling through mutation callers.
- `tests/integration/test-profile-config.cjs` — passed; exact baseline recipe equivalence, generation without documentation, invalid schema and extension rejection.
- `tests/integration/test-docs-reader.cjs` — passed; DOM fixture coverage for navigation, anchors, search feedback, copying, wrapping and print events.
- The four isolated reproductions above, including direct read-only folder help.

Additional documentation and portable-command regression runs passed independently; their final results are recorded in the follow-up evidence below. Native setup, disk operations, application installation, live credentials and real-user state were not exercised.

There is no line-coverage percentage: this was a focused source review with selected regression runs, not instrumented full-suite coverage.

## Blast radius

A lexical call-site count over runtime shell/CommonJS sources, excluding declarations, found:

| Contract | References | Distinct files | Consequence |
| --- | ---: | ---: | --- |
| `day_one_phase_current` | 15 | 9 | Required Phase 8 gate used by optional modules and profile installation |
| `phase_fingerprint` | 3 | 2 | Completion comparison, phase writes and Installation Centre fingerprint |
| `run_phase` | 3 | 1 | Explicit, guided and required-action phase execution |
| `day_one_phase_implementation_hash` | 1 | 1 | Central digest used for all eight phase fingerprints |
| `phase_title` | 7 | 3 | Setup and wizard presentation |
| `phase_doc` | 11 | 11 | Phase guidance and inspection |

Counts are references, not dynamic invocations; a single loop applies the fingerprint contract to all eight phases.

## Safety properties reviewed without a new finding

- `project-paths.sh` retains canonical and legacy state-root selection; relocation does not change the user-data paths.
- `state.sh`, `runtime-package.sh` and `runtime-activation.sh` are substantively unchanged after relocation. Runtime file inventory, regular-file and parent-symlink checks, checksum coverage, atomic activation and recovery-history writes remain present.
- Rollback installs the selected release's own launcher after activation, allowing a baseline release to recover its original dispatch paths.
- The new dependency schema intentionally makes baseline phase evidence stale rather than translating old success into new success. The strengthened `phase_done` explicitly rejects a failed/empty expected digest.
- Profile recipes are read before output creation or extension installation; dry-run returns before file writes or VS Code invocation. Existing new-directory/no-overwrite safeguards and Phase 8 install gate remain.
- Documentation exports retain allowlisted input selection, regular-file/parent checks, new-directory reservation and base64 embedding. The browser retains disabled raw HTML, remote-image suppression and no command execution. Compatibility routing accepts only destinations already in the bundled document map.
- Sensitive cleanup/restore changes inspected were path relocations; destructive confirmation and ownership boundaries were not removed in those diff regions.

## Recommendations and limitations

Resolve R1–R4 and run the targeted negative tests before accepting the restructure. Keep the separately required isolated packaged baseline-upgrade/rollback evidence and full lint/regression results with the implementation record.

This used the differential-review skill's risk-first methodology, adversarial model and reporting guidance. It was a focused review of a large mechanical restructure, not a line-by-line audit of every guide, inherited runtime function or contributor test. All mapping manifests were considered; high-risk runtime paths and relevant changed regions received direct source comparison. No removed authorization, destructive-confirmation, secret-scanning or integrity safeguard was identified in the reviewed regions. This statement is scoped to those regions.

The candidate was being edited concurrently by the implementer; line numbers refer to the initial-review snapshot. Automated fixture evidence does not establish behavior on a managed Mac, real backup volume, MDM enrollment or Apple GUI. Baseline runtime installation and rollback are assigned to the implementer's isolated acceptance run; this report's code inspection must not be described as having executed those transitions independently. Confidence is high in the four reproduced defects and medium in the overall reviewed change.

## Follow-up evidence

- `tests/integration/test-docs.sh` passed: offline export, guide links/anchors, handbook topics, catalogue coverage, privacy, no-overwrite and symlink rejection, plus its reader DOM fixture.
- `tests/integration/test-portable-command.sh` passed: verified/idempotent standalone runtime, checkout-independent execution, second installation and rollback fixture. This runs two versions of the candidate; it is not the separate baseline-to-candidate upgrade acceptance requested by the plan.
- Implementation fixes have not yet been re-reviewed in this initial report.

## Implementer resolution record

All four initial findings were reproduced by
`tests/integration/test-restructure-safety.sh` before the fixes. The same test
then passed after the changes below. This is implementer validation, not a
second independent review.

| Finding | Implemented correction | Negative case covered |
| --- | --- | --- |
| R1 | Validate dependency fingerprints before phase/Installation Centre execution; capture failures before evidence writes; propagate phase errors | Missing manifest or application catalogue is refused; a missing manifest cannot invoke the phase stub, replace old markers, create Installation Centre completion or log success; a failing phase preserves its prior marker |
| R2 | Validate the full TSV schema, unique rows, known phase IDs, safe paths and each phase's own implementation before hashing | Malformed, truncated, duplicate, unknown and unsafe dependency entries are refused |
| R3 | Resolve the folders runner in `src/setup` | Public and compatibility help entry points work from an unrelated directory; existing folder mutation/preservation fixture passes |
| R4 | Syntax-check relocated runtime source as well as compatibility adapters | Invalid syntax injected into a copied phase makes verification fail |

The same safety fixture also reproduced and fixed a setup-centre guide selection
that still opened a legacy stub. The centre now opens canonical guides.

The isolated previous-layout upgrade test passed from source snapshot `0dcfeca`
to an archive built from the candidate and back to the previous runtime. It
verified integrity, manual-guide resolution, profile preview, unchanged old
phase markers, saved ownership/choice fixtures and shell bootstrap files.
The packaged-module fixture passed all 14 active capabilities. Final complete
validation and live activation are recorded in the implementation plan and
acceptance record, separately from this initial review.
