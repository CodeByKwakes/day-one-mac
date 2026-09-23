# Second Brain — choose your knowledge system

[← Day One Mac](../README.md)

This folder contains two complete Second Brain builds. Choose one as the
primary source of truth. Running both for the same notes creates duplicate
inboxes, unclear ownership, and unreliable search results.

## Choose a route

| Choose | Best when | Source of truth | Main tradeoff |
|---|---|---|---|
| [Obsidian](obsidian/README.md) | You want local Markdown files, filesystem control, Git-friendly notes, and locally bounded AI access | Files under `~/Vaults` | Collaboration and structured databases need more design |
| [Notion](notion/README.md) | You want databases, forms, linked views, collaboration, and a visual dashboard | Your Notion workspace | Cloud-first; exports are not a full-fidelity one-click restore |

> 🔴 **Work information:** a filter, tag, `AI Allowed` checkbox, or database
> view is not a security boundary. If an employer requires separation, use a
> separate approved workspace or account and do not connect it to personal AI
> tools.

## Recommended starting point

- Choose **Obsidian** when local ownership and portable Markdown are the main
  priorities.
- Choose **Notion** when quick capture, structured content pipelines, visual
  reporting, and collaboration matter most.
- Do not migrate an entire archive on day one. Build the system, test one
  capture-to-review cycle, then move only active material.

## Independent setup folders

```text
second-brain/
├── README.md          # this chooser
├── obsidian/          # local-vault guides, assets, scripts, and tests
└── notion/            # Notion build guide, planner, seeds, and Raycast assets
```

The two editions are independent. The Obsidian manager writes its own local
vault manifest. The Notion planner stores only non-secret workspace choices
and URLs; it never stores a Notion integration token.
