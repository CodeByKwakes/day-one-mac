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

## Validate a change

\`\`\`bash
cd scripts
bash -n ./*.sh ./lib/*.sh ./tests/*.sh
./validate.sh
\`\`\`

Also inspect:

\`\`\`bash
git diff --check
git status --short
\`\`\`

## Public examples

Use placeholders such as:

\`\`\`text
/Users/your-name
github.com/example-user/example-repository
op://<vault>/<item>/<field>
\`\`\`

Never use a realistic token, even when it has been revoked.
