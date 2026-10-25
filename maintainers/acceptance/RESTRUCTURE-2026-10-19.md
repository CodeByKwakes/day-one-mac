# Restructure acceptance record — 19 October 2026

Baseline: `0dcfeca`. Candidate: the implementation commit containing this record.
Scope: repository organization, configuration extraction, compatibility and
packaged runtime behavior. No public release was published.

## Automated evidence

| Check | Result |
| --- | --- |
| ShellCheck, style severity | Passed: 228 shell scripts |
| Markdown lint | Passed: 257 Markdown files |
| GitHub Actions workflow lint | Passed |
| Static layout and generated reference checks | Passed: 551 allowlisted files, 8 phases, 14 active modules, 100 guide aliases |
| Profile configuration | Baseline recipes preserved; generator works without guides and rejects invalid configuration |
| Dependency/evidence regression | Failed before the fixes; passed afterward, including malformed configuration and retained prior evidence |
| Documentation reader/export | Offline navigation, old anchors, export privacy, existing-destination and symlink refusal passed |
| Packaged modules | Passed all 14 active capabilities, including plan/apply/check/resume and drift handling in fixtures |
| Previous-layout upgrade/rollback | Passed from extracted `0dcfeca` through a candidate archive and back, using a temporary home with spaces and Unicode |
| Full static and regression gate | Passed: `tools/validate.sh --all`, exit 0 |

Required-action and previous-layout upgrade/rollback fixtures were rerun after
the final fingerprint error-propagation guard and passed. The complete gate
also passed its final restructure-safety fixture, including that guard.

The upgrade fixture checks old completion markers and saved ownership/choice
files byte-for-byte. Existing shell bootstrap files remain unchanged. The
candidate reports old fingerprints as requiring revalidation; it does not
manufacture current completion evidence.

## Reproducing the checks

Run the ordinary contributor commands in [Contributing](../../CONTRIBUTING.md).
The separate previous-layout fixture accepts an extracted source tree:

```bash
baseline_dir="$(mktemp -d /tmp/day-one-baseline.XXXXXX)"
git archive 0dcfeca | tar -x -C "$baseline_dir"
/bin/bash tests/integration/test-runtime-upgrade.sh "$baseline_dir"
```

That baseline commit must exist locally. The fixture itself performs no network
fetch and uses temporary homes. The standard suite also tests installing two
candidate versions and rollback without requiring historical Git objects.

The local pnpm launcher could not verify its requested package-manager identity
because registry access failed. Markdown lint used the already installed
`node_modules/.bin/markdownlint-cli2`; shell and workflow tools ran directly.
No signature check was disabled. The project maintenance skill's frontmatter
and local references were validated with the installed Node YAML parser because
the optional Python skill validator lacked PyYAML.

## Independent review and limits

The [independent differential review](../audits/RESTRUCTURE-DIFFERENTIAL-REVIEW-2026-10-19.md)
identified four defects. Each has a reproduced failing test and a passing fix.
The review report retains its original findings and a separate resolution record.

Fixture acceptance does not establish macOS 27 onboarding, MDM enrollment,
physical peripheral compatibility, provider sign-in or a restore from a real
backup device. Release-readiness and mounted-restore plan commands resolve and
remain read-only; the native mounted-volume rehearsal was not run for this
restructure. Keep these requirements in the existing release acceptance matrix.
