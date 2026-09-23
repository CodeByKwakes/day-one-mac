# 6 — Raycast integration 🤖 ⚙️ Optional

[← Dashboard](05-DASHBOARD.md) · [AI integration →](07-AI-INTEGRATION.md)

## Purpose

Open the dashboard or capture form without navigating through Notion.

## Recommended route: Quicklinks

After creating the HQ page and private capture form:

1. Copy the HQ page URL.
2. Copy the capture form URL.
3. Rerun the planner:

   ```bash
   ./scripts/notion-second-brain-manager.sh --guided --apply
   ```

4. Enter the two URLs when asked.
5. In Raycast, create Quicklinks named:
   - Open Second Brain HQ
   - Capture to Second Brain
6. Paste the matching URL and assign optional keyboard shortcuts.

Quicklinks are simpler than an API integration and contain no API secret.

## Script Commands created by the planner

When Raycast is selected, the planner installs two small commands under:

```text
~/.local/share/second-brain-notion/raycast
```

Add that folder in Raycast:

1. Open Raycast Settings.
2. Open **Extensions**.
3. Add a Script Commands directory.
4. Select the folder above.
5. Run **Open Notion Second Brain** and **Capture to Notion Second Brain**.

The commands read the URLs from
`~/.config/second-brain-notion/config`. If a URL is missing, they explain how
to add it instead of opening an incorrect page.

## Search

Use Notion's workspace search or desktop Command Search for full-text search.
A Raycast Quicklink can open the Knowledge database, but it is not a replacement
for Notion's search index.

## Advanced API capture

Add direct API capture only if a Quicklink or form is too slow. If implemented
later:

- Create a least-privilege Notion integration.
- Share only the intended database with it.
- Store the token in 1Password, not in a script or this repository.
- Preview the page payload before sending it.
- Fail closed if the target database is unknown.
- Log the new page URL, never the token.

The current planner intentionally does not create or store API credentials.

Next: [AI integration →](07-AI-INTEGRATION.md)
