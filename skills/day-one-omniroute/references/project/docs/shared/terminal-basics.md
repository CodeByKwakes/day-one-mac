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
are in the [plain-English glossary](glossary.md).

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
| bold cyan heading with one icon | current screen |
| bold blue heading | section within a screen |
| cyan row with `>` | current keyboard selection |
| `🔒` | required and not toggleable |

Colours are automatically removed when output is saved to a file or used by
automation. To turn colours off manually, place `NO_COLOR=1` before a command:

```bash
NO_COLOR=1 day-one-mac --status
```

The words and symbols remain, so plain output and screen readers retain the
same meaning.

## Compact menus and status screens

Menus show a window of choices sized for your terminal. Use Up/Down or `j`/`k`
to move through the entire list; the item counter shows your position. The
`>` marker remains visible with colour disabled. Space toggles checkboxes;
Enter accepts the selection or opens its review. Keyboard hints stay below
the choices.

The setup confirmation starts with a short review. Press `d` to show or hide
all setup details before accepting. Dry-run reviews still print the full plan.
Optional CLI tools show one category at a time, with a description of the
focused tool. Left/Right or `h`/`l` changes categories and retains selections.

The optional status dashboard shows all modules and keeps installed/missing
payload breakdowns for selected modules. For additional evidence and next
actions, including skipped modules, run:

```bash
day-one-mac optional --status --details
```

Headings use light dividers, cyan screen titles and blue section titles.
Interactive screen titles have one icon; section titles stay text-only.
Redirected output keeps plain titles without colour or heading icons.
`TERM=dumb` disables screen-clearing sequences as well as colour. For ASCII
symbols in the shared status messages, use:

```bash
DAY_ONE_MAC_ASCII=1 NO_COLOR=1 day-one-mac shell --status
```
