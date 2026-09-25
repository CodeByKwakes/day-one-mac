# Contributing

Thank you for improving Day One Mac.

## Before changing code

1. Read [Start Here](docs/START-HERE.md) and the affected phase or module.
2. Keep required Phases 1–8 separate from optional Modules 9–14 and advanced
   Modules 15–22.
3. Never add real credentials, private keys, personal inventories, company
   names, private repository names, vault names or absolute personal paths.
4. Keep scripts compatible with the Bash 3.2 included with macOS.
5. Make mutations idempotent, preview-first where destructive, and precisely
   recorded for rollback.
6. Use the `day-one-mac` portable command in user-facing instructions. Show
   direct scripts only in contributor, low-level troubleshooting, or recovery
   sections, and state why the direct form is needed.
7. Treat the public release installer and versioned standalone runtime as the
   normal distribution path. A source checkout is optional development state.

## Validate a change

```bash
cd scripts
bash -n ./*.sh ./lib/*.sh ./tests/*.sh
./validate.sh
```

Also inspect:

```bash
git diff --check
git status --short
```

## Release workflow

Use Conventional Commit subjects so Release Please can select the next
semantic version:

- `fix:` proposes a patch release;
- `feat:` proposes a minor release;
- `feat!:` or another explicit breaking-change marker proposes a major release.

Do not update `VERSION`, create a release tag, or publish a GitHub Release by
hand during normal development. After validation succeeds on `main`, Release
Please updates one release pull request containing `VERSION`, `CHANGELOG.md`,
and the release manifest. Review and merge that pull request when the changes
are ready to publish. The release workflow then creates the tag and GitHub
Release and attaches the verified runtime archive, checksum, and installer.

Repository maintainers must keep the narrowly scoped `RELEASE_PLEASE_TOKEN`
Actions secret available so the generated release pull request receives the
normal validation workflow.

## Public examples

Use placeholders such as:

```text
/Users/your-name
github.com/example-user/example-repository
op://<vault>/<item>/<field>
```

Never use a realistic token, even when it has been revoked.
