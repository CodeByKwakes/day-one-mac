[← Operating system](OPERATING-SYSTEM.md) · **Alternatives** · [Checklist →](CHECKLIST.md)

# Alternative tool stacks

The Obsidian designs prioritise local Markdown, portability, direct file
access, and one workflow across development and content creation. These are the
best alternatives when another priority matters more.

## 1. Logseq + Raycast Script Commands + Claude Code

**Choose it when:** daily notes and outlining match how you think better than
folders and documents.

### You gain

- Block-first notes and strong bidirectional linking.
- A natural journal/outliner workflow for rapid learning logs.
- Local files that Claude Code can inspect.
- Raycast Script Commands can open the graph or append to a file.

### You lose

- Obsidian's mature folder-based workflow and core Bases dashboards.
- Some predictability when external tools edit block identifiers or graph
  metadata.
- The exact templates and `.base` files included in this project.

### Fit for the three domains

Good for continuous software-learning logs. Less natural for long-form content
pipelines unless you deliberately add page properties and export steps.

## 2. DEVONthink + Raycast or macOS Shortcuts

**Choose it when:** document capture, PDFs, email archives, OCR, and powerful
local retrieval matter more than Markdown portability.

### You gain

- Strong document ingestion, classification, OCR, and local search.
- Better handling of large mixed-format research libraries.
- Deep macOS automation options.

### You lose

- A plain-folder source of truth that Git and terminal agents understand
  naturally.
- Easy review of every change as a Markdown diff.
- Simple cross-platform portability and publishing from source files.

### Fit for the three domains

Excellent as a research archive beside a smaller writing system. It can become
heavy as the primary place for code-linked development notes and content
drafts.

## 3. Notion + Notion AI + Command Search

**Choose it when:** team collaboration, polished databases, shared publishing
calendars, and permissions matter more than local ownership.

### You gain

- Strong collaborative databases and dashboards with little setup.
- Built-in AI search across the workspace and supported connected apps on
  eligible plans.
- A consistent web/mobile experience and easy sharing.

### You lose

- Local Markdown as the canonical source.
- Full offline behaviour for all advanced blocks and AI features.
- Straightforward Git history and safe direct editing by terminal tools.
- Some control over pricing, export fidelity, and long-term tool independence.

### Fit for the three domains

Best for a team content calendar and shared documentation. Weaker for a private,
offline-first developer brain or when work policy forbids combining data in a
cloud workspace.

## Decision matrix

| Priority | Obsidian + Raycast | Obsidian + Claude Code | Obsidian + Codex | Logseq stack | DEVONthink stack | Notion stack |
|---|:---:|:---:|:---:|:---:|:---:|:---:|
| Local-first Markdown | Excellent | Excellent | Excellent | Good | Limited | Poor |
| Fast macOS capture/search | Excellent | Good | Good | Good | Good | Good |
| AI synthesis over files | Optional | Excellent | Excellent | Good | Limited/custom | Excellent, plan-dependent |
| Visual databases/dashboard | Good | Good | Good | Fair | Fair | Excellent |
| PDF/OCR research archive | Fair | Fair | Fair | Fair | Excellent | Good |
| Team collaboration | Fair | Fair | Fair | Fair | Fair | Excellent |
| Git review and portability | Excellent | Excellent | Excellent | Good | Poor | Poor |
| Strong physical work separation | Good with separate vault | Good with separate vault | Good with separate vault | Good with separate graphs | Excellent with databases | Workspace/admin dependent |

## Recommended choice for this use case

Start with **Obsidian + Raycast** if capture and retrieval are the immediate
pain. Add Claude Code after the folder/property habits and work-policy boundary
are stable.

Start with **Obsidian + Claude Code** if you already capture notes reliably and
the immediate need is synthesis and reuse. Add Raycast later for lower-friction
capture.

Choose **Obsidian + Codex** for the same synthesis use case when Codex is
already your approved agent environment. Its vault-root `AGENTS.md`, bounded
working directory, sandbox, and approval mode should be reviewed together.

Use **both** only after each path passes its checklist independently. The
combined stack is powerful because it separates concerns: Raycast gets
knowledge in and finds it; Obsidian is the human interface and source of truth;
Claude Code or Codex proposes transformations under review.

Official references: [Logseq documentation](https://docs.logseq.com/),
[DEVONthink documentation](https://docs.devontechnologies.com/), and
[Notion workspace search](https://www.notion.com/help/search).

---

[← Operating system](OPERATING-SYSTEM.md) · [Completion checklist →](CHECKLIST.md)
