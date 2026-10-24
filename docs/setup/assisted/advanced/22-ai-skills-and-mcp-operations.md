[← Advanced 21](21-audit-maintenance-and-rebuild.md) · **🤖 ⚙️ Advanced 22**

# Advanced 22 - Shared AI skills and MCP operations

**Time:** 45-120 minutes · **Required:** no · **Prerequisites:** Optional 10 and, for MCP, Optional 11

## Outcome

Selected AI clients share reviewed reusable skills from one source where their
discovery models permit it. Client-specific agents remain separate, MCP servers
have an inventory and owner, trust is explicit, secrets stay out of Git, and
unused capabilities can be disabled or removed cleanly.

## Executable inventory and drift route

Module 22 can record an owner and content hash for each explicitly selected
skill or MCP metadata manifest. A hash detects content changes; it does not
prove that the content is safe or that the owner reviewed it. The runner never
executes skill instructions/helpers, creates client links, changes trust
settings or reads a live client credential file.

Create `governance.tsv` in your editor, with four tab-separated fields:
`skill` or `mcp`, a short name, owner label and absolute path. Replace these
example paths with your own:

```text
skill	code-review	platform-team	/Users/your-name/.agents/skills/code-review
mcp	project-tools	platform-team	/Users/your-name/Developer/project/mcp.tsv
```

A skill path must be one folder containing `SKILL.md`, not your home directory
or the whole skills library. The entire selected folder is hashed, including
its helpers and references. MCP paths must point to the five-column metadata
manifest from [Module 11](../optional/11-mcp-servers.md#executable-workspace-snippet-route),
not `.mcp.json` or a live client configuration. Symlinks are rejected; select
the canonical source instead of a compatibility link.

Docker profiles and their exported JSON are outside this manifest format.
Record their owner, reviewed image references and client verification manually
using the [Docker MCP guide](../../manual/ai/mcp-docker.md); do not treat a
passing Module 22 snapshot as evidence that a Docker gateway is restricted or
working.

```bash
day-one-mac advanced --module 22 --plan --manifest ./governance.tsv
day-one-mac advanced --module 22 --apply --manifest ./governance.tsv
day-one-mac advanced --module 22 --check
```

Apply requires Phase 8 and confirmation. Read `evidence.tsv` and `report.md`
at the printed artifact path. Check fails for changed, missing, unreadable or
unsafe inputs. It does not modify the baseline. The snapshot stores hashes
and ownership labels, not copies of skill contents.

After a change, run `--plan` and review the diff before accepting a new
baseline with `--apply`. To retry a failed snapshot using the saved paths, use
`--resume`. Resume captures **current contents**, so its confirmation also
accepts a new baseline; it is not a security approval. Previous snapshots
remain available. A failed apply saves a diagnostic snapshot and returns a
failure status, never a false success.

Finish the manual ownership, compatibility, trust and decommissioning
checklists below. The dashboard remains `partial` for a passing executable
snapshot; it cannot certify those decisions.

## Complete the shared manual actions

Follow the linked task for the selected actions, verify them, then return here. Manual configuration has one owner; the module records evidence.

| Manual action | Guide |
|---|---|
| 1. Record the selected clients and purpose | [Open task](../../manual/ai/maintenance.md#1-record-the-selected-clients-and-purpose) |
| 2. Use one canonical personal skill source | [Open task](../../manual/ai/maintenance.md#2-use-one-canonical-personal-skill-source) |
| 3. Add compatibility links only where needed | [Open task](../../manual/ai/maintenance.md#3-add-compatibility-links-only-where-needed) |
| 4. Start with three narrow skills | [Open task](../../manual/ai/maintenance.md#4-start-with-three-narrow-skills) |
| 5. Keep client-specific agents separate | [Open task](../../manual/ai/maintenance.md#5-keep-client-specific-agents-separate) |
| 6. Maintain one MCP inventory | [Open task](../../manual/ai/maintenance.md#6-maintain-one-mcp-inventory) |
| 7. Add one server through one client first | [Open task](../../manual/ai/maintenance.md#7-add-one-server-through-one-client-first) |
| 8. Apply client-specific scope rules | [Open task](../../manual/ai/maintenance.md#8-apply-client-specific-scope-rules) |
| 9. Use secrets by reference | [Open task](../../manual/ai/maintenance.md#9-use-secrets-by-reference) |
| 10. Keep approval and trust visible | [Open task](../../manual/ai/maintenance.md#10-keep-approval-and-trust-visible) |
| 11. Verify selected clients independently | [Open task](../../manual/ai/maintenance.md#11-verify-selected-clients-independently) |
| 12. Disable and remove cleanly | [Open task](../../manual/ai/maintenance.md#12-disable-and-remove-cleanly) |

## Advanced 22 completion checklist 🚦

- [ ] Only purpose-backed AI clients are installed and recorded.
- [ ] Personal skills have one canonical, secret-free source.
- [ ] Compatibility links resolve and no whole client directory is shared.
- [ ] Client-specific agents declare scope, permissions, and failure behaviour.
- [ ] Every MCP server has purpose, scope, credential method, clients, and owner.
- [ ] Each server passed one read-only test before wider rollout.
- [ ] Filesystem, browser, database, and paid-tool scopes are narrow.
- [ ] Global auto-approval remains disabled.
- [ ] No credential appears in skills, configs, dotfiles, Warp, or Git.
- [ ] Disable/removal and provider-revocation procedures are understood.

```bash
day-one-mac advanced --complete 22
```

---

[← Advanced 21](21-audit-maintenance-and-rebuild.md) · [Advanced index](README.md) · [Day One Mac home](../../../README.md)
