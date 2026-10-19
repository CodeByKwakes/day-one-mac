# 2 — Workspace and domains

[← Prerequisites](01-PREREQUISITES.md) · [Databases and properties →](03-DATABASES-AND-PROPERTIES.md)

## Purpose

Create one stable home page and make domains editable data instead of
hardcoded folders.

## Create Second Brain HQ

1. Open the approved Notion workspace.
2. Create a new private page named **Second Brain HQ**.
3. Add this short description:

   > The entry point for capture, search, projects, sources, review, and
   > knowledge across approved domains.

4. Add temporary headings: Quick Capture, Inbox, Active Projects, Content
   Pipeline, Sources to Verify, AI Review, Weekly Review, and Analytics.
5. Do not add confidential content yet.

## Create the Domains database

1. Under HQ, type `/database`.
2. Choose **Table — Full page**.
3. Name it **Domains**.
4. Rename the title property to **Domain**.
5. Add these properties:

| Property | Type | Example |
|---|---|---|
| Domain | Title | Software Development |
| Kind | Select | Personal, Work, Shared |
| Sensitivity | Select | Public, Personal, Confidential, Work Restricted |
| AI Policy | Select | No AI, Review Only, Approved |
| Active | Checkbox | Checked |
| Owner | Person or Text | Your name or team |
| Notes | Text | Short boundary explanation |
| Knowledge | Relation | Added after Knowledge exists |
| Knowledge Count | Rollup | Count related Knowledge pages |

6. Add one row for every chosen domain.
7. Set conservative defaults: `AI Policy = No AI` until reviewed.

## Decide whether to separate work

If work requires separate permissions:

1. Create the work system in its approved teamspace or workspace.
2. Do not share the personal HQ with the work account merely for convenience.
3. Do not create a relation across boundaries unless policy explicitly permits
   it.
4. Keep a short, non-confidential handoff note if knowledge must be recreated
   in both systems.

## Importing the starter domain list

The repository includes `seeds/domains.csv` as an example. After apply, the
planner also writes a customised copy containing your selected domains under
`~/.local/state/second-brain-notion/seeds/`. Importing CSV is optional:

1. Open Domains.
2. Use the database menu and choose **Merge with CSV** or import the CSV as
   supported by the current Notion interface.
3. Review every row.
4. Recreate property types, because CSV import cannot fully reproduce relations,
   rollups, permissions, templates, or automations.

## Completion gate

- [ ] Second Brain HQ exists in the correct workspace.
- [ ] Domains exists and contains only approved domains.
- [ ] Sensitivity and AI Policy are reviewed.
- [ ] Work information has the required permission boundary.

Next: [Databases and properties →](03-DATABASES-AND-PROPERTIES.md)
