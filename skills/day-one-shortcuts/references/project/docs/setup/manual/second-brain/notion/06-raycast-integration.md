# 6 - Raycast integration 🤖 ⚙️ Optional

[← Dashboard](05-dashboard.md) · [AI integration →](07-ai-integration.md)

## Purpose

Open the dashboard or capture form without navigating through Notion.

## Create and verify Quicklinks

Prerequisites: Raycast is installed, and your private HQ page and capture form already open successfully in Notion.

1. Copy the HQ page URL from Notion. Expected: the URL opens your intended private page.
2. In Raycast, run **Create Quicklink** and save the URL as **Open Second Brain HQ**. Expected: the new command appears in Root Search.
3. Copy the private capture form URL from Notion. Expected: it opens the form for your intended workspace.
4. Create a second Quicklink named **Capture to Second Brain** using that URL. Expected: it opens the capture form.
5. Submit a harmless test note through the second Quicklink. Expected: the note appears in the intended Notion database with the expected access controls.

Quicklinks contain URLs, not API secrets. If a page is missing, check the signed-in Notion account and page permissions before changing the link. Remove the test note after verifying capture.

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

This Quicklink workflow needs no API credentials.

Next: [AI integration →](07-ai-integration.md)
