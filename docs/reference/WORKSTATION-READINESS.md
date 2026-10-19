[← Start here](../START-HERE.md) · [Pilot acceptance](../how-to/recovery/WORKSTATION-ACCEPTANCE.md)

# Personal and managed workstation readiness

Day One Mac separates developer-tool installation from workstation acceptance.
A completed phase is recorded evidence for its current selections and code.
It is not a permanent claim about device health, software trust or compliance.

## Choose ownership before setup

The script-assisted wizard asks **Who manages this Mac?** Choose personal for a
personally administered device, or managed for an organization-enrolled device.
Hosting Tracks 1–4 describe repository providers; they do not describe MDM.
Direct setup accepts `--deployment personal|managed` and `--policy PATH`.
Existing selections default to personal; detection of enrollment blocks personal
apply and asks for a reviewed managed policy. The scripts do not unenroll Macs,
demote accounts, modify secure tokens or handle recovery keys.

For a managed Mac, IT must first:

1. Assign the Mac to its approved enrollment process and complete Setup Assistant.
2. Create the daily standard account and provision an approved administrator or
   elevation mechanism. Check SSO, secure/bootstrap tokens, recovery access and
   offboarding ownership using the management system.
3. Apply the approved OS/update policy, FileVault recovery escrow, firewall
   rules, security agents, certificates, privacy permissions and login items.
4. Provision native Homebrew through the approved administrator workflow when
   required. The managed route does not run the public Homebrew bootstrap.
5. Approve a workstation policy and record the preflight evidence below.

The macOS preferences checkpoint is skipped in managed mode. Local preference
apply/restore is blocked: the policy owner must make those changes. Other
application installers still honor external/MDM application ownership.

Apple documents [managed account provisioning](https://support.apple.com/guide/deployment/set-up-local-macos-accounts-depca092ad96/web),
[secure/bootstrap tokens](https://support.apple.com/guide/deployment/use-secure-and-bootstrap-tokens-dep24dbdcf9e/web),
and [FileVault management](https://support.apple.com/guide/deployment/manage-filevault-with-device-management-dep0a2cb7686/web).
Use the organization's approved baseline; no universal regulatory baseline is
assumed. The [macOS Security Compliance Project](https://pages.nist.gov/macos_security/)
can help the security owner select and maintain one.

## Policy contract

### Acceptance controls for both setup routes

Use this matrix before setup and again at final acceptance. The manual route
uses macOS/IT checks and a private operator-kept record; it does not require
Day One Mac commands. The assisted route uses the selected policy and current
device/account-bound evidence. Neither route replaces organization approval.

| Control | Personal Mac | Managed Mac | Acceptance evidence |
|---|---|---|---|
| Ownership and account | Personally administered account | Enrollment, daily standard account and approved elevation/recovery owner | IT verifies MDM, profiles, SSO and secure/bootstrap tokens where applicable |
| OS and updates | Supported OS with current applicable updates | Approved OS build and update deadline; do not bypass a deferral | Record OS build, policy revision and check date |
| FileVault and Gatekeeper | Both enabled | Both enabled, with recovery escrow verified by IT | Required in both routes; exceptions do not satisfy Day One Mac completion |
| Firewall and SIP | Enabled under the personal baseline | Organization-approved controls | Current observations; any supported exception needs an approval reference |
| Recovery | Separate recovery method and a successful recovery drill | Approved escrow, break-glass and workload recovery checks | Record outcome and custody references, never keys or credentials |
| Software and preferences | Selected software and reviewed personal preferences | Approved publishers/installers; IT owns managed preferences | Homebrew is provisioned by the approved administrator; local preference apply/restore is blocked |
| Organization acceptance | Add controls required for the workload | Startup, lock/sharing, endpoint agents, privacy, software/editor scopes, network, restoration, peripherals, performance and onboarding | Retained tests for every control in the approved policy; see [pilot acceptance](../how-to/recovery/WORKSTATION-ACCEPTANCE.md) |

Manual records identify the policy/baseline, device and account using private
non-secret references, reviewer, check time, expiry and evidence location. Use
the selected policy's evidence interval (personal default: seven days); renew
after expiry or relevant policy/device/account changes. The scripted JSON
format is needed only for assisted acceptance. Never mark an untested control
as passed. An approved exception is distinct from an observed pass.

### Policy file

The bundled [managed policy example](../../config/policies/managed-policy.example.json)
is deliberately **unapproved**. Copy it to private administration storage,
review every required control, select the supported OS range and record a
non-secret approval reference. Set `approved` to `true` only after that review.
Do not commit an organization's policy, identities or internal endpoint list.

Policy fields:

| Field | Meaning |
|---|---|
| `schema` | `1` |
| `mode` | `personal` or `managed`; must match the selected route |
| `baseline` | Stable baseline identifier, letters/numbers/dot/underscore/hyphen |
| `approved`, `approval_reference` | Required for managed policy; local records of the owning authority's decision |
| `minimum_major`, `maximum_major` | Approved OS major range within 15–27 |
| `max_evidence_hours` | Maximum attestation age/lifetime, 1–336 hours; default personal policy is 168 |
| `required` | Known control IDs; mandatory controls cannot be omitted |
| `endpoints` | Up to 20 approved `{ "id": "service", "url": "https://…/" }` objects |
| `software` | Optional catalogue application IDs mapped to approved bundle, team and version observations |

An optional `software` record has this shape; the administrator supplies actual
values from an independently approved publisher and release:

```json
{
  "application-id": {
    "bundle_id": "approved.bundle.identifier",
    "team_id": "APPROVEDTEAM",
    "versions": ["approved-version"]
  }
}
```

Do not copy an observed team identifier into an allowlist without establishing
its trusted source. When configured, missing/conflicting installations,
unverified signatures, Gatekeeper rejection, absent arm64 support or a version
outside the allowlist block the publisher gate. Presence/ownership detection
remains separate. Licenses, CLI provenance and first launch require manual evidence.

Network checks send HTTPS HEAD requests to approved URLs, with a ten-second
limit each. Credentials, URL query strings and fragments are refused; redirects
are not followed, response bodies and raw errors are not printed. A 401/403/405
response establishes TLS/HTTP reachability only. Authenticated access, PAC,
802.1X, split DNS, VPN and certificate renewal still require the network check.
Never disable certificate validation to make a check pass.

## Script-assisted inspection and evidence

These commands use the installed runtime. Python 3 must already be available
through the approved developer tools; inspection never installs it implicitly.

```bash
day-one-mac readiness --plan
day-one-mac readiness --plan --mode managed --policy /path/to/approved-policy.json
```

Plans list applicable controls without saving state or probing the machine.
For a managed pilot, first inspect the plan, then create a private template:

```bash
day-one-mac readiness --init-evidence "$HOME/.day-one-mac/workstation-evidence.json" \
  --mode managed --policy /path/to/approved-policy.json
```

For a personal Mac, omit `--mode managed --policy …`. Its default policy requires
an OS within the dependency range, FileVault, Gatekeeper, application firewall,
SIP and a current recovery attestation. An organization can require more controls.

The template starts with every status `unknown`. Complete it only after doing
the work. Each manual control needs:

- `status`: `pass`, or `exception` with a reason and approval reference;
- `checked_at` and `expires_at`: UTC timestamps ending in `Z`;
- `reviewer_reference` and `evidence_reference`: non-secret references to the
  responsible operator and retained evidence;
- for exceptions, `reason` and `approval_reference`.

Keep recovery keys, passwords, tokens, serial numbers and profile payloads out
of this file. The evidence is bound to the policy hash, device and current
account. Missing, future-dated, expired or mismatched evidence remains UNKNOWN.
An observed automatic failure cannot be replaced by a claimed manual PASS.
**FileVault and Gatekeeper are non-waivable:** FAIL or UNKNOWN remains blocking
even when an exception is recorded, matching required Phases 3 and 8. For other
automatic controls, an explicit current exception can supersede failure when
the policy owner approves it. Publisher allowlist and endpoint failures require
correction; manual PASS or EXCEPTION does not override those additional checks.

```bash
day-one-mac readiness --check --json
day-one-mac readiness --preflight --mode managed --policy /path/to/approved-policy.json
```

Before setup saves the managed selection, supply `--mode` and `--policy` to
inspection commands. Afterward, the command loads them from saved state.
Managed preflight checks enrollment, daily account privilege, management
ownership and elevation evidence. Phase 8 runs the full selected readiness
policy. The report distinguishes PASS, PASS-MANUAL, EXCEPTION, FAIL and UNKNOWN.
FAIL/UNKNOWN cannot produce successful completion. Exit 10 means unresolved
controls; exit 2 means invalid policy/input or unavailable device binding.

To renew evidence, retain the old record privately, create a new template at a
new path, complete fresh checks, then deliberately replace the active evidence.
Policy changes require fresh evidence. Output creation refuses existing files
and symlink paths. Records are created with mode 600; they are operator
attestations, not signed server-side compliance certifications.

## Record software and version drift

```bash
day-one-mac readiness --software-inventory "$HOME/Downloads/app-observations.json"
day-one-mac readiness --snapshot "$HOME/Downloads/baseline-observations.json"
day-one-mac readiness --compare "$HOME/Downloads/baseline-observations.json"
```

The application inventory records observed catalogue bundle IDs, versions,
signatures, team IDs, code hashes, Gatekeeper assessment and native architecture.
It does not sign into or launch applications. Keep it private. Review its
unapproved/unknown results against the owning administrator's software policy.

The version snapshot records observed OS/build, Homebrew package versions and
selected tool versions. Unknown probes remain unknown. Comparison reports drift
or missing evidence; matching observations do not prove identical application
bytes, user data or configuration. Use project runtime pins and lockfiles in
addition to a machine baseline. Refresh managed allowlists through patch review;
do not freeze vulnerable versions indefinitely.

Database Module 09 stores resolved immutable image digests separately. It pins
a verified local Unix-socket context, refuses endpoint drift and unowned
resources, and checks recorded container launch specifications. It defaults to
2 GiB and two CPUs per service with no automatic restart. Fixed credentials
require explicit `--disposable-data`: use synthetic data only. The guided
selection labels this restriction before apply. Use separately administered
services for sensitive/production data. Existing resources are never silently
adopted, relabelled or replaced; see [database recovery](../how-to/modules/optional/09-databases.md).

## Manual route

Do not run the commands above if you chose the manual route. Use the same
control descriptions and [pilot checklist](../how-to/recovery/WORKSTATION-ACCEPTANCE.md)
to maintain your own dated evidence. The manual route does not create project
completion markers or automated evidence files.
