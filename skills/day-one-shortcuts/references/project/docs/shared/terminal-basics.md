# Terminal basics

[Back to Start here](../START-HERE.md)

## Terminal basics used in this guide

**Terminal** is the macOS application in which you enter text commands. Open it
from **Applications → Utilities → Terminal** or with Spotlight.

- Copy only the text inside a code block, not the surrounding backticks.
- Paste one command block at a time and press Return.
- A command that starts with `#` is an explanation; it does not make a change.
- Text such as `<repository>` is a placeholder. Replace the complete text,
  including angle brackets, with your real value.
- When macOS asks for an administrator password in Terminal, no dots or letters
  appear while you type. This is normal. Type the password and press Return.
- `Control-C` stops the current command. Inspect the result before repeating a step; an interruption may leave partial work.
- `~` means your home folder, such as `/Users/alex`.

Definitions for recurring terms such as CLI, cask, gate, manifest, and vault
are in the [plain-English glossary](glossary.md).

## Check command results

A successful command normally exits with status `0`. Read its output and the
owning guide's expected result. Stop on an unexpected result before running the
next step. A version number proves availability, not working account access.

Commands beginning with `npx skills` install or manage AI skills; `day-one-mac`
in an AI prompt names a skill, not a shell command. The legacy command is retired.

<a id="terminal-colours-and-symbols"></a>
<a id="compact-menus-and-status-screens"></a>
