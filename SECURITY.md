# Security policy

## Supported version

Only the newest published Day One Mac release is supported with security
updates. A previous installed runtime remains available locally for rollback,
but it may not contain current fixes.

## Report a vulnerability privately

Do not open a public issue containing a credential, private key, personal
inventory, unsafe deletion path, or reproducible security exploit.

Use GitHub's **Security** → **Advisories** → **Report a vulnerability** workflow
for this repository. Include the affected version, macOS version, command,
expected result and observed result. Redact usernames, company names, tokens,
vault names and recovery paths.

If a real credential was exposed, revoke or rotate it before preparing the
report. Removing it from the latest commit does not remove it from Git history.

## Safety guarantees

Day One Mac is designed to:

- support native Apple-silicon macOS only;
- keep cleanup and rollback preview-first;
- avoid disk erase and formatting;
- keep secrets outside the repository and generated reports;
- verify standalone runtime archives before installation;
- preserve software it did not install unless the user explicitly selects a
  broader reviewed cleanup.

Please report any behaviour that violates those boundaries.
