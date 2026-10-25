---
name: day-one-check
description: Audit an existing Day One Mac environment and report evidence, missing prerequisites and configuration drift without repairing it. Use before changes or when verifying setup.
---

# Day One check

Use [verification](references/project/docs/shared/verification.md), the selected manual
capability guide and [utility reference](references/project/docs/shared/reference/tools.md).

Inspect only the requested scope. Capture tool versions, installation owner,
configuration checks and a harmless functional result. Do not infer success
from a completion marker, executable presence alone or an old report.

Use read-only checks where possible. A probe that starts a service, writes a
file or contacts an account needs the corresponding authorization. With a
read-only agent, ask the operator or user for that probe's result.

Report each capability as verified, incomplete, failed or not checked, with the
command/evidence and practical consequence. Separate suggested repairs from the
audit. Do not install, update, activate MCP, change credentials or clean files.

## Installed package

Resolve bundled links relative to this skill directory, not the working directory.
The project reference snapshot is under `references/project/`; use its matching
paths when a guide refers to supplied configuration or template files. Read only
the guide needed for the current task. Keep this installed package unchanged.

Save private notes outside this installed package. No Day One Mac runtime is required.
Reviewed helpers are bundled under `references/project/helpers/`; inspect their
help and preview output before approving changes. Manual recipes need no helpers.
