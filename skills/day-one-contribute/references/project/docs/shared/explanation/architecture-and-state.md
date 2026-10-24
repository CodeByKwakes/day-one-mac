# Architecture and saved state

Manual guides own tool recipes. AI skills select those recipes and add planning,
approval, verification and maintenance instructions. Skill installation copies
its required references and reviewed helpers so the checkout is unnecessary.

`templates/skills/` and `templates/agents/` are maintained sources. `skills/`
contains generated packages with content checksums. Those checksums detect
changes; they do not authenticate an unknown publisher. Review the source and
Git revision before installation.

Helpers read their adjacent configuration. They have no installed manager or
global state store. Private session notes and explicitly selected recovery
backups live outside the installed skill. Updating a skill must not erase them.

Existing `~/.day-one-mac` records are legacy recovery evidence. Follow
[legacy removal](../migration/remove-legacy-manager.md) before moving them.
They are not completion evidence for current tools.

<a id="runtime-architecture-and-state"></a>
<a id="responsibilities"></a>
<a id="state-and-ownership"></a>
<a id="packaging-and-updates"></a>
<a id="assistant-workspaces"></a>
