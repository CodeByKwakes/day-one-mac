# Repository organization

| Area | Responsibility |
|---|---|
| `docs/setup/manual/` | Canonical runnable recipes |
| `docs/setup/ai/` | Client preparation and assistant operation |
| `docs/shared/` | Prerequisites, verification, helper references and migration |
| `templates/skills/`, `templates/agents/` | Maintained instructions and native roles |
| `skills/` | Generated independent installation packages |
| `helpers/` | Bounded helpers bundled with skills |
| `config/` | Reviewed source inventories and configuration data |
| `tools/`, `tests/` | Contributor generation, static export and validation |
| `integrations/`, `extensions/` | Reviewed native-tool workflows and templates |
| `maintainers/` | Current contributor guidance and dated historical evidence |

No optional runtime, global CLI or manager state is part of this architecture.
The approved migration is in [the no-runtime plan](../plans/2026-10-25-no-runtime.md).
The source inventories exclude private notes and unreviewed files. Generated
bundle checksums detect drift without coupling to a runtime version number.

<a id="repository-organization-and-migration"></a>
<a id="boundaries-and-ownership"></a>
<a id="compatibility-and-saved-evidence"></a>
<a id="documentation-and-profile-data"></a>
<a id="packaging-and-acceptance"></a>
