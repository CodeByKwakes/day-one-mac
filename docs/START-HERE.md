# Start here

Choose one setup route for your Apple-silicon Mac. Both routes prepare the same
selected development capabilities; they record and recover changes differently.

| Route | Use it when | Begin |
|---|---|---|
| Scripted (Assisted) Setup | Policy permits local scripts and you want resumable checks and recorded ownership | [Assisted setup](setup/assisted/README.md) |
| Manual Setup | You want to perform each installation and edit yourself, or policy prohibits the project scripts | [Manual setup](setup/manual/README.md) |

## Before you begin

Read the [shared prerequisites](shared/prerequisites.md), then complete the
[decision worksheet](shared/decisions.md). Keep the worksheet and recovery
information privately. If this Mac holds the only copy of important data, stop
and verify a separate backup before proceeding.

A managed Mac needs your organisation's approved software, identity and elevation
process. Mobile device management (MDM) settings remain owned by IT.

## Optional AI choice before setup

Choose no AI, guidance only, or approved local execution before Phase 1.
Reuse one approved client, or prepare it through the
[manual AI checkpoint](setup/manual/ai/setup-assistant.md) or
[assisted AI checkpoint](setup/assisted/ai-setup-assistant.md) for your route.
If a reset is still planned, use browser guidance until the starting boundary
is ready. Additional clients and MCP can wait until the base works.

## Choose one setup route

The assisted route installs the standalone `day-one-mac` command. It does not
need a permanent Git checkout. Its required work ends with Phase 8; optional
modules remain separate.

The manual route uses macOS and the selected tools directly. It does not install
or call Day One Mac scripts, create phase markers or promise automated rollback.
Record each result and backup yourself.

Both routes include human actions such as accepting licences, approving account
access and testing a backup. An assisted guide links to the exact manual task
and states when to return. Complete that task once.

## Get help or continue later

- [Troubleshooting](shared/troubleshooting.md) routes a symptom to its owning guide.
- [Terminal basics](shared/terminal-basics.md) explains commands and placeholders.
- [Glossary](shared/glossary.md) defines unfamiliar terms.
- [Process overview](shared/explanation/process-overview.md) explains the two journeys.
- [All documentation](README.md) lists tasks by route and topic.

Do not treat a successful installation command as proof of account access,
application permissions or recoverability. Use the guide's verification step.

## Previously published section links

Existing bookmarks remain available below. Use the route and task links above
for the normal setup sequence.

### What this project does

Continue with [How setup fits together](shared/explanation/process-overview.md).

### Personal or managed Mac

Continue with [Check prerequisites](shared/prerequisites.md).

#### Script-assisted route — recommended

Continue with [Scripted (Assisted) Setup](setup/assisted/README.md).

#### Manual route — no Day One Mac scripts

Continue with [Manual Setup](setup/manual/README.md).

### Terminal basics used in this guide

Continue with [Terminal basics](shared/terminal-basics.md).

### Terminal colours and symbols

Continue with [Terminal basics](shared/terminal-basics.md).

### Install the standalone command for the script-assisted route

Continue with [Install and manage the standalone runtime](setup/assisted/runtime.md).

### Run the recommended route

Continue with [Scripted (Assisted) Setup](setup/assisted/README.md).

### Understand preview and apply

Continue with [Scripted (Assisted) Setup](setup/assisted/README.md).

### One change that needs your password

Continue with [Install and manage the standalone runtime](setup/assisted/runtime.md).

### Stop, resume, and get help

Continue with [Find the right troubleshooting procedure](shared/troubleshooting.md).

### How to read each phase

Continue with [Scripted (Assisted) Setup](setup/assisted/README.md).

### Set up the required applications

Continue with [Required Installation Centre](setup/assisted/INSTALLATION-CENTRE.md).

### After Phase 8

Continue with [Optional Day One Mac modules](setup/assisted/optional/README.md).
