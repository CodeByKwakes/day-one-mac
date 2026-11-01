# Reader keyboard source review

**Two keyboard defects were corrected and their regressions pass.** This review
examined source and the existing DOM fixture on 1 November 2026. It does not
establish browser or assistive-technology acceptance. Overall readiness remains
**Not ready** under the [current acceptance procedure](../acceptance/CURRENT-READINESS.md).

## Scope and baseline

The baseline was `990fc528493117c69b6391b4828f75327db3e19a`. Review covered
`tools/docs/docs-browser.js`, its HTML and CSS, the reader fixture in
`tests/integration/test-docs-reader.cjs` and the
[reading guide](../../docs/shared/reading-and-export.md).
The existing fixture passed before changes.

The source includes a skip link, labelled navigation and search, status messages,
focus handling for headings and menus, copy fallback and print styles. Their
presence is not proof that they work with a particular browser or screen reader.

## Findings and repairs

1. **Character-only search shortcut.** The global keydown handler captured `/`
   outside editable fields without an off switch, remapping control or
   component-focus restriction. Excluding editable fields does not satisfy the
   [WCAG character-shortcut requirement](https://www.w3.org/WAI/WCAG22/Understanding/character-key-shortcuts.html).
   The handler now uses Command+K or Ctrl+K and ignores composition, already
   handled events, extra Alt/Shift modifiers and editable fields. The visible
   hint, `aria-keyshortcuts` and reading guide match the handler.
2. **Legacy section targets lacked keyboard focus support.** The renderer
   preserves exact inert `<a id>` anchors for compatibility. Navigation called
   their `focus()` method, but only headings received a `tabindex`. Resolved
   section targets now receive `tabindex="-1"` before focus, allowing programmatic
   focus without adding a tab stop. See the
   [HTML focus rules](https://html.spec.whatwg.org/multipage/interaction.html#the-tabindex-attribute).

## Verification and limits

The added legacy-anchor assertion first failed because `tabindex` was absent.
After that repair, the shortcut regression failed because `/` was still
intercepted. After both repairs, the fixture passed in website and offline modes.
It checks shortcut matching, ignored input, search/menu state, accessible shortcut
metadata and the legacy target's focusability attribute alongside existing
navigation, search, copy and print-event assertions.

The fixture's `focus()` method assigns its active element directly; it does not
model browser focus eligibility. The explicit `tabindex` assertion catches the
source defect, but actual keyboard focus and announcements still need a browser.
Private evidence retains the baseline, both failing results and passing result.

No browser check ran. The earlier browser access denial remains a boundary;
no alternate access route was used. Browser shortcut conflicts, VoiceOver,
rendered contrast, narrow layout, 200% zoom, clipboard integration and actual
printing remain unverified. No live provider, device or macOS 15 check ran.

The [installed Claude acceptance](2026-11-01-native-claude-installed-acceptance.md)
and [installed Codex acceptance](2026-11-01-native-codex-acceptance.md) retain their
own package identities. These reader changes do not update an installed plugin
or extend those live-client results to a newer package.
