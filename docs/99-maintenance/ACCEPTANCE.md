[← Maintainer material](README.md)

# Rehearse a release candidate

This guide is for contributors preparing a release, not someone setting up
their daily Mac. It explains how to test the packaged command without
installing into your real home directory, and how to exercise restore staging
on a disposable APFS volume. It does not publish, authenticate accounts or run
the eight required setup phases on your real machine.

## 1. Prepare the contributor tools

Use a native Apple-silicon terminal and the
[contributor tooling guide](../CONTRIBUTOR-TOOLING.md). Node 22+, the locked pnpm
dependencies, ripgrep, ShellCheck and actionlint must already be available.
The acceptance runner never installs a missing tool. The native rehearsal
also uses macOS `hdiutil` and `plutil`.

Run commands from a source checkout, not from an installed runtime. Acceptance
scripts and contributor dependencies are deliberately excluded from the
runtime archive.

## 2. Preview the checks

```bash
pnpm run acceptance:plan
pnpm run acceptance:native:plan
```

Both commands are read-only: they do not create reports, state, locks, disk
images or mounts. Read the selected gates before running them.

## 3. Rehearse the packaged command

```bash
pnpm run acceptance:package
```

This builds the allowlisted release archive, installs it into a disposable
home directory, verifies checksums and checks all 15 capability entries. It
exercises Modules 17, 18 and 20 through the installed launcher, followed by
Module 21 and the status dashboard. Identity drift and read-only state checks
must behave the same as in a checkout. Temporary fixtures are removed after
the test; no real user configuration is edited.

The fixture writes its own Phase 1–8 markers to reach guarded module actions.
Those markers are **test prerequisites, not evidence of a successful Mac
onboarding**. The normal validator separately tests the other module runners
with controlled fixtures. Neither test implies account access or GUI readiness.

## 4. Optionally rehearse a real mounted volume

Preview again if needed, then choose a new private output directory whose
parent already exists. Use a physical path, not a symlink such as `/tmp`:

```bash
scripts/rehearse-mounted-restore.sh --plan
scripts/rehearse-mounted-restore.sh --run \
  --output-dir /private/tmp/day-one-native-review-001
```

The runner refuses existing output directories. It builds and installs the
candidate into that directory, creates a 64 MiB APFS image, and mounts it at a
unique `/Volumes/DayOneAcceptance-*` path. Only generated text files are placed
on it. There is no option to select an existing disk or backup.

The native checks cover:

- read-only plan/check and the Phase 8 gate;
- byte-identical staging from an actual mounted filesystem;
- recovery of a deliberately missing staged file;
- refusal to overwrite a deliberately changed destination;
- refusal of changed source bytes and an unmounted source.

This is a missing-file recovery rehearsal, not a power-loss simulation.
Interrupted-write fault injection is covered by the normal regression suite.

Afterward, inspect `native-result.json`. Success requires `status: passed` and
`cleanup: detached`. The image, fixture home, staging records and preserved
test file remain in the output directory as evidence. Their paths and the
candidate archive's SHA-256 are recorded. The runner does not delete this
evidence or force-detach busy volumes.

## 5. Collect release-readiness evidence

```bash
scripts/release-readiness.sh --run \
  --output-dir /private/tmp/day-one-release-review-001 \
  --native-volume
```

Omit `--native-volume` to skip mounting; the report will explicitly mark that
gate skipped. It will **not** reuse an earlier native result. Use a new output
path for every run and keep it outside the checkout.

The runner builds one candidate archive and passes that exact file to both
packaged and native tests. It records the commit, code fingerprint, archive
hash, individual gate results and private logs. Read `report.md` for a summary
and `report.json` for machine-readable details. Checks continue after failures
where safe, so one missing tool does not hide other results.

Do not edit candidate source while this command runs. A changed source digest
or commit makes the run fail. A dirty checkout is reported even when the tests
pass; commit and rerun to collect evidence for one reviewable revision.

## Reference: gates and exit status

| Gate | Checks | Mutations |
|---|---|---|
| `build` | Allowlisted runtime archive and checksums | New release assets inside the report directory |
| `lint` | Normal `pnpm run lint`, with no hidden acceptance-specific exclusions | None intended |
| `workflow-lint` | Installed actionlint against the workflows | None intended |
| `validation` | Full structural and regression suite | Disposable test fixtures |
| `packaged-runtime` | Installed candidate Modules 17/18/20/21 and capability registry | Disposable home, repositories and state |
| `native-volume` | Real APFS fixture and Module 20 safety checks | Its own retained image, mount and fixture state; detach on completion |

Exit `0` means selected automated gates passed and source stayed unchanged.
Exit `1` means a failed/blocked gate, invalid environment/output, or changed
candidate source. A skipped native gate and dirty source do not by themselves
change exit `0`, but prevent `candidateChecksPassed` from becoming true.
Invalid invocation is reported as an error; consult `--help`.

Report fields deliberately distinguish:

- `automatedPassed`: build, lint, workflow lint, validation and packaged test
  all passed; missing or pending gates do not count.
- `nativePassed`: this run's native-volume gate passed.
- `sourceClean` / `sourceUnchanged`: clean Git status and stable candidate inputs.
- `candidateChecksPassed`: all of the above, including native coverage.
- `releaseApproved`: always false; an automated report cannot approve a release.

The source digest covers versioned and unignored candidate files, excluding
local `.agents/`, `.claude/` and `skills-lock.json` content. Their dirty Git
status is still visible through `sourceClean`, and normal project lint retains
its own configured scope. Reports store hashes rather than source contents.
Git symlinks are recorded without following their targets.

Each gate has a 30-minute deadline. Logs are streamed to private files, and
the report is updated between gates. A leftover `running`/`pending` result or
missing finish time is incomplete evidence, never a pass. Disk-image commands
also have bounded subprocess deadlines. A hard kill or power failure can still
leave an attached image; use the recovery procedure below.

## Recovery and cleanup

If native cleanup fails, stop and inspect the recorded image and mount paths.
Use `hdiutil info` to match that **exact image** to its device before detaching
it. Do not detach a guessed disk identifier or any real backup volume. The
runner only detaches a device found in the matching image's mount metadata.

Keep evidence until review is complete. Once the fixture image is confirmed
detached, archive or trash that specific output directory through your normal
file-management workflow. Never recursively remove `/Volumes`, `/private/tmp`
or a repository/home directory as cleanup. An existing report is not a resume
target: rerun into a new output directory.

## Human release checklist

- [ ] Review all gate failures, skips, logs and source cleanliness.
- [ ] Run required Phases 1–8 in a fresh supported user/device environment;
  record macOS/architecture, selected track, stack and authentication mode.
- [ ] Verify the chosen provider accounts, actual signing, application imports,
  trust approvals and GUI/security settings with their module guides.
- [ ] Review [candidate release notes](RELEASE-CANDIDATE.md), compatibility and
  known limitations; attach evidence to the reviewed commit.
- [ ] Use the existing protected-branch checks and Release Please process.
  Do not infer publication approval from a local test report.

The `Validate` workflow now runs packaged acceptance after the full validator.
Native mounting remains opt-in. No release is published by these scripts, and
the version and generated changelog remain owned by Release Please.
