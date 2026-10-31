# 9 - Backup, export, and recovery expectations

[← Operating workflow](08-operating-workflow.md) · [Checklist →](checklist.md)

## Purpose

Create an independent copy and understand what it can and cannot restore.

## Export routine

Once a month, or before a major redesign:

1. In Notion on desktop or web, open **Settings → General**.
   Expected: settings for the intended workspace are visible.
2. Select **Export all workspace content**. For one page instead, use that
   page's **••• → Export** menu. Expected: the intended export scope is selected.
3. Choose **Markdown & CSV** and review the inclusion options. Complete the
   export and download it through Notion's provided link. Expected: a ZIP arrives;
   a successful request alone is not a downloaded backup.
4. Save the download under a dated folder such as:

   ```text
   ~/Documents/Notion Exports/Second Brain/2026-09-18/
   ```

5. Copy that dated folder to the encrypted backup used by Day One Mac.
6. Open the archive.
7. Confirm Knowledge, Projects, Sources, attachments, and several page bodies
   are present.
8. Record the verification date in your Weekly or Monthly Review.

If export is unavailable, check your workspace role and administrator policy.
The export excludes content your account cannot access; compare the result with
your intended scope before claiming a complete backup. Do not change sharing
just to make export work. The [official backup procedure](https://www.notion.com/help/back-up-your-data)
was checked on 30 October 2026; labels and policy controls can change.

## Important limitation

An export is not a complete one-click workspace restore. Views, permissions,
relations, rollups, formulas, comments, automations, forms, and page history may
need reconstruction.

Keep a copy of:

- this guide;
- the saved setup plan;
- the database property tables;
- screenshots or notes describing important views and permissions;
- the latest verified export.

## Recovery exercise

At least once after the initial build:

1. Create a temporary local folder.
2. Extract the export there.
3. Open representative Markdown and CSV files.
4. Confirm attachments are readable.
5. Compare five important pages with Notion.
6. Remove the temporary extracted test only after recording the result.

## Completion gate

- [ ] A dated export exists outside Notion.
- [ ] It has been copied to encrypted backup storage.
- [ ] Representative pages and files open.
- [ ] I understand which cloud features the export will not restore.

Next: [Completion checklist →](checklist.md)
