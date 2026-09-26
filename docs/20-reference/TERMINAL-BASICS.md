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
- `Control-C` stops the current command. Rerun the phase afterward; do not
  manually mark it complete.
- `~` means your home folder, such as `/Users/alex`.

Definitions for recurring terms such as CLI, cask, gate, manifest, and vault
are in the [plain-English glossary](GLOSSARY.md).

## Terminal colours and symbols

Interactive Day One scripts use colour and symbols to make the next action
easier to spot. Meaning never depends on colour alone:

| Display | Meaning |
|---|---|
| green `✓` | completed successfully |
| yellow `⚠` | warning or review required |
| red `✗` or `⛔` | failed or stopped |
| blue `ℹ` | information only |
| grey `○` | pending work |
| cyan title or highlighted row | current screen or selection |
| `🔒` | required and not toggleable |

Colours are automatically removed when output is saved to a file or used by
automation. To turn colours off manually, place `NO_COLOR=1` before a command:

```bash
NO_COLOR=1 day-one-mac --status
```

The words and symbols remain, so plain output and screen readers retain the
same meaning.
