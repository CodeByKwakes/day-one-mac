# Developer Resources

Keep supporting project material and reusable resources here. Keep active Git
repositories in `~/Developer/Projects`; experiments belong in `Sandbox` and
inactive work in `Archive`.

## Folder guide

| Folder | What belongs here |
|---|---|
| `Project-Materials/` | Material for one project that you keep outside its Git repository: source assets, working CSV files and exports |
| `Shared-Assets/` | Images, icons, fonts and brand kits reused across projects |
| `Datasets/` | Reusable datasets and sanitised sample data |
| `Templates/` | Project starters, document templates and configuration examples |
| `Reference/` | Specifications, technical PDFs and learning material |
| `Scripts/` | Reusable standalone utilities; keep project-specific scripts in their repository |
| `VSCode/` | Exported editor settings, profiles, themes and extension lists |
| `Warp/` | Custom terminal themes, workflows, launch configurations and exports |
| `Raycast/` | Script commands, quicklink definitions, snippets and exports |

These are starting points, not mandatory categories. Leave unused folders empty
and add subfolders when you need them. Day One Mac preserves existing contents.

## Material for a particular project

Use the same project name as the repository so the relationship is clear:

```text
~/Developer/
├── Projects/
│   └── example-app/             # Git repository
└── Resources/
    └── Project-Materials/
        └── example-app/
            ├── assets/         # Original artwork and working assets
            ├── csv/            # Working imports and extracts
            └── exports/        # Reports and generated deliverables
```

Create those per-project subfolders yourself when needed. Folder setup does not
invent project names, move files or create links into repositories.

Files needed to build, test or run the project should usually live in its
repository, following that project's conventions. This external folder is for
supporting material that does not need to be committed. Putting files here does
not automatically exclude them from Git if you initialise a repository here.

## Shared resources and editor exports

Organise shared folders by purpose, for example `Shared-Assets/icons`,
`Datasets/sample-orders` or `Templates/web-app`. Setup creates these app folders:

```text
Resources/
├── VSCode/
│   ├── Settings/
│   ├── Profiles/
│   ├── Extensions/
│   ├── Snippets/
│   ├── Themes/
│   └── Workspaces/
├── Warp/
│   ├── Themes/
│   ├── Workflows/
│   ├── Launch-Configurations/
│   └── Exports/
└── Raycast/
    ├── Script-Commands/
    ├── Quicklinks/
    ├── Snippets/
    └── Exports/
```

Use these for reusable files, exports and reference copies. Applications continue
using their normal configuration locations; folder setup does not install apps,
activate settings or import exports. Keep workspace files and editor settings in
the project repository when they are useful to the team. Keep extension
development in `Projects`.

## Archive finished work

Setup also creates these folders alongside Resources:

```text
~/Developer/Archive/
├── Projects/             # Retired repositories
├── Experiments/          # Sandbox work worth retaining
├── Project-Materials/    # Supporting material for retired projects
└── Exports/              # Old reports and deliverables
```

Move work here manually when you decide it is inactive. Use matching project
names in `Projects` and `Project-Materials`, and add year folders such as
`Exports/2026` when useful. A project README can explain why it was archived and
how to run it. Setup does not move projects or create project/year folders.

## Database backups

For local development database dumps, keep working copies outside the Git
repository, grouped by project and database engine:

```text
~/Developer/Resources/Project-Materials/example-app/
└── database-backups/
    ├── postgres/
    │   └── example-app_2026-10-11.dump
    ├── mysql/
    └── sqlite/
```

Create only the project and engine folders you need. This is a suggested storage
location; Day One Mac does not create database dumps, schedule backups or verify
restores. Keep a separate copy on an encrypted external drive or an approved
backup service, and periodically test a restore into a disposable database.
A dump on the same laptop is vulnerable to loss of that laptop.

Production or customer data belongs in your organisation's approved backup
storage, with its access and retention rules. Do not commit database dumps to
Git. Keeping them outside a repository avoids accidental inclusion during normal
project commits, but does not sanitise their contents or encrypt them. If you
archive a project, retain its backups only as long as appropriate for that data.

## Care and maintenance

This folder is local storage, not a backup or an access-control system. Use
approved storage for sensitive exports and include material you want to keep in
your backups. Do not put passwords, tokens or private keys in templates or data.

The purpose-oriented Day One Mac setup creates missing folders and this README.
An existing README is left unchanged. Rerunning folder setup repairs missing
folders without deleting their contents or moving repositories. Changing layout
does not remove this structure. Rollback uses the setup journal; review its plan
before applying it, especially once folders contain your own material.
