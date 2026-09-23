# 5 — Second Brain HQ dashboard

[← Templates](04-TEMPLATES.md) · [Raycast →](06-RAYCAST-INTEGRATION.md)

## Purpose

Turn Second Brain HQ into a working queue rather than a decorative home page.

## Add quick actions

At the top of HQ, add buttons or prominent links for:

- New Capture
- New Development Note
- New Content Idea
- New Source
- Start Weekly Review

Database buttons can add pages with predefined properties. Test each button
with a disposable page before relying on it.

## Add linked views

Type `/linked`, select the database, and apply these filters:

| View | Database | Filter or grouping |
|---|---|---|
| Inbox | Knowledge | Status = Inbox |
| Recent Knowledge | Knowledge | Last Edited within the last 7 days |
| Development | Knowledge | Domain = Software Development; group by Status |
| Software Content | Knowledge | Domain = Software Content; board by Status |
| Tech Content | Knowledge | Domain = Tech Content; board by Status |
| Active Projects | Projects | Status = Active |
| Sources to Verify | Sources | Verification is Unchecked or Recheck |
| AI Review | Knowledge | AI Status = Needs Review |
| Review Due | Knowledge | Review Date is today or earlier |

Hide properties that are irrelevant to each view. This changes presentation,
not permissions.

## Add useful analytics

Start with four signals:

- Number of Inbox items.
- Knowledge pages by Domain.
- Content pages by Status.
- Sources awaiting verification.

Optional additions:

- Notes created per week.
- Projects without a next action.
- Knowledge not edited for 90 days.
- Published items by Channel.

Charts and dashboard views depend on current Notion features and plan. A linked
table or board is an acceptable fallback.

## Global filters

Where dashboard views support shared filters, add:

- Domain
- Sensitivity
- Status
- Date

Never treat these as access control.

## Keep it useful

Place action queues above charts. A dashboard should answer:

1. What needs attention?
2. What am I actively working on?
3. What is unsafe or incomplete?
4. What changed recently?

Next: [Raycast integration →](06-RAYCAST-INTEGRATION.md)
