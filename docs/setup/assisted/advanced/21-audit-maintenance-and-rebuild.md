[← Advanced 20](20-restore-and-migrate.md) · **🤖 ⚙️ Advanced 21** · [Advanced 22 →](22-ai-skills-and-mcp-operations.md)

# Advanced 21 - Audit, maintenance, and rebuild

**Time:** 30-90 minutes initially; 20-30 minutes monthly · **Required:** no

## Outcome

The expanded environment has a repeatable audit, updates happen in small
reviewable layers, dotfiles and Brewfile changes are committed privately, and
a clean-Mac rebuild is rehearsed without relying on remembered manual steps.

## 1. Revalidate the project and required base

### Snapshot bounded setup evidence

Use the executable Module 21 route for a write-free preview and a versioned
comparison of recorded setup evidence:

```bash
day-one-mac advanced --module 21 --plan
day-one-mac advanced --module 21 --apply
day-one-mac advanced --module 21 --check
```

Plan and check write no records, reports or temporary files. Apply requires
Phase 8 and confirmation, then prints a private artifact path containing
`report.md`, stable `evidence.tsv` and the remaining manual steps. Subsequent
applies compare against the previous snapshot and keep every older version.
Check returns nonzero for changed evidence, a failing gate, a damaged snapshot
or no saved baseline. Review the differences before applying a new baseline.

The scope is deliberately bounded: runtime verification, presence and hashes
of required completion records, explicit non-secret selection hashes,
checks for saved executable-module selections, and recorded Advanced guide
fingerprints. Module 21 excludes its own guide marker to avoid self-generated
drift. A development checkout receives entry-point checks, not a packaged
checksum guarantee. Phase record presence does **not** prove the phase is still
current or the machine healthy; use the existing required status and Phase 8
verification below for that.

No account clients, login shells, package upgrades, Brewfile evaluation,
repository cleanup or rebuild commands are launched by this snapshot route.
It is not the broader environment audit in Step 21.2 and does not verify
FileVault, accounts, repository backups or recovery readiness.

A failing audit still saves its diagnostic snapshot and returns nonzero.
Fix the reported issue, then use `day-one-mac advanced --module 21 --resume`
to capture fresh evidence. Resume never performs the fix. Generating a healthy
report does not mark this guide complete; record completion separately only
after reviewing the applicable checklist.

### Recheck the full required setup

```bash
day-one-mac validate
day-one-mac --status
day-one-mac advanced --status
```

The required eight phases must remain current. An advanced marker becoming
`review` means its guide changed after completion; read the module and
repeat only its affected checks.

## 2. Generate the extended audit

This is an **optional after-setup health report**. Use it after Phase 8 when you
have adopted advanced Modules 15-22, and repeat it during monthly maintenance.
It is not the Stage 0 safety report used before erasing or cleaning an existing
Mac.

Run the bundled read-only report:

```bash
day-one-mac advanced-audit
```

It writes `~/.day-one-mac/advanced-audit.md` and checks the base command
surface, Brewfile drift, chezmoi state, ghq repositories, selected track and
stack, optional containers, and discovered AI clients without printing tokens.

Open the report locally:

```bash
sed -n '1,260p' "$HOME/.day-one-mac/advanced-audit.md"
```

An optional component is reported as absent, not failed, unless its advanced
module is recorded complete.

## 3. Review Homebrew updates in layers

Complete the [manual package maintenance steps](../../manual/maintenance.md#1-inspect-homebrew-metadata). Review candidates and recovery before upgrading; return here after the selected project checks pass.

### Optional GUI cleanup with Purge

If Purge is selected, preview its installation owner:

```bash
day-one-mac applications --id purge
day-one-mac applications --id purge --install-missing
```

Then follow the [manual application checks](../../manual/maintenance.md#8-verify-selected-services-and-applications). Permissions and cleanup decisions remain manual; no Day One Mac command runs Purge for you.

## 4. Maintain Node, npm, and pnpm ownership

Follow [project runtime maintenance](../../manual/maintenance.md#5-check-project-runtimes). Retain the selected package-manager owner and test each project against its declarations before changing runtime defaults.

## 5. Maintain Python through uv

Use the Python branch of [runtime maintenance](../../manual/maintenance.md#5-check-project-runtimes). Sync the declared environment and run the project's own test instructions before returning.

## 6. Review chezmoi and Brewfile drift

Complete [configuration drift review](../../manual/maintenance.md#6-review-configuration-drift) through the selected owner. Back up a local-only source or commit reviewed files when private Git is selected.

## 7. Review every repository before system work

Use [repository review](../../manual/maintenance.md#7-review-repositories-before-system-work). Preserve uncommitted work, unpushed commits and repositories without remotes before system changes.

## 8. Verify optional services

### Containers and databases

Follow [service maintenance](../../manual/maintenance.md#8-verify-selected-services-and-applications), including an isolated restore check before database changes.

### AI and MCP

Complete [AI maintenance](../../manual/ai/maintenance.md) for only the selected clients and servers.

### VS Code and GUI applications

Use the [application checks](../../manual/maintenance.md#8-verify-selected-services-and-applications), then return to this module. Settings Sync alone is not a complete backup.

## 9. Use a maintenance cadence

Adopt the [maintenance cadence](../../manual/maintenance.md#9-record-a-maintenance-cadence) or your organisation's required schedule.

## 10. Rehearse the rebuild

Prepare the private inventory and independent backups described in
[manual rebuild preparation](../../manual/maintenance.md#10-rehearse-a-manual-rebuild).
On a separate approved Mac, use the [public assisted installer](../README.md)
and `day-one-mac` wizard with the recorded choices. Complete the human
checkpoints and Phase 8 there. Install only selected optional modules afterward.

On the current Mac, a preview can inspect the saved selection:

```bash
day-one-mac setup --plan
day-one-mac setup --status --json
```

Expected result: a proposed sequence and current evidence. This preview does
not prove installation or recovery on another Mac. Do not run setup on the
working Mac as a substitute for a separate rebuild rehearsal.

## 11. Test rollback without executing it

```bash
day-one-mac rollback
day-one-mac clean
```

Review the preview output and recovery archive plan. Do not run `--execute` as
a routine test. A useful rollback rehearsal proves exact ownership and backup
destinations without deleting the working environment.

## Advanced 21 completion checklist 🚦

- [ ] Required and advanced progress reports contain no unexplained review state.
- [ ] The extended audit has no unexplained failure.
- [ ] Homebrew updates are reviewed before upgrade or cleanup.
- [ ] If Purge is selected, scheduling is disabled, Full Disk Access is
      understood, and no overlapping general-purpose cleaner is installed.
- [ ] fnm/Node/npm/pnpm and uv have one owner each.
- [ ] chezmoi and Brewfile drift are understood and privately committed.
- [ ] Dirty, ahead, and `NO-REMOTE` repositories are resolved or documented.
- [ ] Optional services pass harmless smoke tests.
- [ ] A maintenance cadence and pre-upgrade backup gate are recorded.
- [ ] The rebuild inputs and sequence are complete.
- [ ] Both cleanup modes have been previewed and understood.

```bash
day-one-mac advanced --complete 21
```

---

[← Advanced 20](20-restore-and-migrate.md) · [Continue to Advanced 22 →](22-ai-skills-and-mcp-operations.md)
