#!/usr/bin/env python3
"""Read-only workstation checks and bounded, device/policy-bound manual evidence.

Local records are operator attestations, never independent compliance proof.
No credentials, profile payloads, process command lines or recovery keys are read.
"""
import argparse
import datetime as dt
import hashlib
import json
import os
import plistlib
import pwd
import statistics
import signal
import time
from pathlib import Path
import re
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request

CONTROLS = {
    'os': 'Supported and approved macOS version',
    'filevault': 'Disk encryption enabled',
    'gatekeeper': 'Gatekeeper assessments enabled',
    'firewall': 'Application firewall enabled',
    'sip': 'System Integrity Protection enabled',
    'enrollment': 'Device management enrollment active',
    'standard-user': 'Daily account is a standard user',
    'management': 'Approved enrollment, profiles, SSO and account ownership',
    'elevation': 'Approved administrator/elevation and break-glass process',
    'recovery': 'Recovery custody and unlock procedure verified without recording keys',
    'startup': 'Approved startup policy and secure/bootstrap-token readiness',
    'updates': 'Approved OS build and update deadlines satisfied',
    'lock-sharing': 'Lock timeout, sharing and inbound exceptions approved',
    'endpoint': 'Required endpoint/security agents healthy',
    'privacy': 'Privacy permissions, extensions and login items approved',
    'software': 'Sources, publishers, versions, licenses and first launch verified',
    'editor-scopes': 'Effective editor policy, profiles and workspaces reviewed',
    'network': 'Corporate/home/VPN, proxy, DNS and certificate acceptance',
    'restore': 'Selected data classes restored; metadata, application import and RPO/RTO verified',
    'peripherals': 'Required devices pass reconnect, sleep/wake and accessibility checks',
    'performance': 'Setup, shell, apps, idle resources and recovery budgets measured',
    'onboarding': 'Fresh-user run, restart persistence and accessibility accepted',
}
AUTO = {'os', 'filevault', 'gatekeeper', 'firewall', 'sip', 'enrollment', 'standard-user'}
PERSONAL = ['os', 'filevault', 'gatekeeper', 'firewall', 'sip', 'recovery']
PREFLIGHT = {'enrollment', 'standard-user', 'management', 'elevation'}


def command(args, timeout=15):
    process = None
    try:
        process = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            text=True, stdin=subprocess.DEVNULL, start_new_session=True)
        out, err = process.communicate(timeout=timeout)
        return process.returncode, out.strip(), err.strip()
    except (OSError, subprocess.TimeoutExpired):
        if process is not None:
            try:
                os.killpg(process.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            process.communicate()
        return 124, '', ''


def load(path):
    def unique(pairs):
        out = {}
        for key, value in pairs:
            if key in out:
                raise ValueError('duplicate JSON key')
            out[key] = value
        return out
    with open(path, encoding='utf-8') as source:
        return json.load(source, object_pairs_hook=unique, parse_constant=lambda _: (_ for _ in ()).throw(ValueError('non-JSON constant')))


def policy_for(args):
    policy = load(args.policy) if args.policy else {
        'schema': 1, 'mode': 'personal', 'baseline': 'personal-v1',
        'minimum_major': 15, 'maximum_major': 27, 'required': PERSONAL,
        'max_evidence_hours': 168, 'endpoints': [],
    }
    if not isinstance(policy, dict) or policy.get('schema') != 1 or policy.get('mode') != args.mode:
        raise ValueError('policy schema or deployment mode mismatch')
    if not re.fullmatch(r'[A-Za-z0-9_.-]{1,80}', str(policy.get('baseline', ''))):
        raise ValueError('baseline needs a stable identifier')
    required = policy.get('required')
    if not isinstance(required, list) or not all(isinstance(x, str) and x in CONTROLS for x in required):
        raise ValueError('unknown required control')
    if len(required) != len(set(required)):
        raise ValueError('duplicate control')
    minimum = set(CONTROLS) if args.mode == 'managed' else set(PERSONAL)
    if not minimum.issubset(required):
        raise ValueError('policy cannot omit mandatory controls; use reviewed exceptions for non-applicable controls')
    if args.mode == 'managed' and (policy.get('approved') is not True or not policy.get('approval_reference')):
        raise ValueError('managed policy needs approval and a non-secret approval reference')
    for key, low, high in [('minimum_major', 15, 27), ('maximum_major', 15, 27), ('max_evidence_hours', 1, 336)]:
        if type(policy.get(key)) is not int or not low <= policy[key] <= high:
            raise ValueError('invalid policy version or evidence interval')
    if policy['minimum_major'] > policy['maximum_major']:
        raise ValueError('invalid supported OS range')
    software = policy.get('software', {})
    if not isinstance(software, dict):
        raise ValueError('invalid software policy')
    catalogue_ids = {line.split('\t')[0] for line in (Path(__file__).resolve().parents[2]/'config/applications.tsv').read_text().splitlines()
                     if line and not line.startswith('#') and line.split('\t')[5] == 'app'}
    for app_id, record in software.items():
        if app_id not in catalogue_ids or not isinstance(record, dict) or not record.get('team_id') or not record.get('bundle_id'):
            raise ValueError('invalid publisher policy')
        if not isinstance(record.get('versions'), list) or not record['versions'] or not all(isinstance(v, str) for v in record['versions']):
            raise ValueError('software versions must be an explicit nonempty allowlist')
    endpoints = policy.get('endpoints', [])
    if not isinstance(endpoints, list) or len(endpoints) > 20:
        raise ValueError('at most 20 approved endpoints are supported')
    seen = set()
    for item in endpoints:
        if not isinstance(item, dict) or not re.fullmatch(r'[a-z][a-z0-9-]{0,40}', item.get('id', '')):
            raise ValueError('invalid endpoint label')
        if item['id'] in seen:
            raise ValueError('duplicate endpoint label')
        seen.add(item['id'])
        url = urllib.parse.urlsplit(item.get('url', ''))
        if url.scheme != 'https' or not url.hostname or url.username or url.password or url.query or url.fragment:
            raise ValueError('endpoints must be HTTPS without credentials, query or fragment')
    return policy


def fingerprint(policy):
    return hashlib.sha256(json.dumps(policy, sort_keys=True, separators=(',', ':')).encode()).hexdigest()


def device():
    code, out, _ = command(['/usr/sbin/ioreg', '-rd1', '-c', 'IOPlatformExpertDevice'])
    match = re.search(r'"IOPlatformUUID"\s*=\s*"([A-Za-z0-9-]+)"', out)
    if code or not match:
        raise ValueError('cannot bind evidence to this Mac')
    user = pwd.getpwuid(os.getuid()).pw_name
    code, account, _ = command(['/usr/bin/dscl', '.', '-read', '/Users/' + user, 'GeneratedUID'])
    identity = re.search(r'GeneratedUID:\s*([A-Fa-f0-9-]+)', account)
    if code or not identity:
        raise ValueError('cannot bind evidence to this account')
    return hashlib.sha256((match[1] + ':' + identity[1]).encode()).hexdigest()


def timestamp(value):
    if not isinstance(value, str) or not value.endswith('Z'):
        raise ValueError('timestamps must use UTC Z')
    return dt.datetime.fromisoformat(value[:-1] + '+00:00')


def manual(control, evidence, policy, binding, now):
    if evidence.get('schema') != 1 or evidence.get('policy_sha256') != fingerprint(policy) or evidence.get('device') != binding:
        return 'UNKNOWN', 'Missing or mismatched device/policy evidence'
    record = evidence.get('controls', {}).get(control, {})
    try:
        checked, expires = timestamp(record.get('checked_at')), timestamp(record.get('expires_at'))
        age = (now - checked).total_seconds()
        if not 0 <= age <= policy['max_evidence_hours'] * 3600 or not checked < expires or expires <= now:
            raise ValueError('stale evidence')
        if (expires - checked).total_seconds() > policy['max_evidence_hours'] * 3600:
            raise ValueError('excessive evidence lifetime')
        if not record.get('reviewer_reference') or not record.get('evidence_reference'):
            raise ValueError('missing references')
        if record.get('status') == 'pass':
            return 'PASS-MANUAL', 'Current operator attestation; evidence retained by its owner'
        if record.get('status') == 'exception' and record.get('reason') and record.get('approval_reference'):
            return 'EXCEPTION', 'Current documented exception; approval retained by its owner'
    except (ValueError, TypeError, AttributeError):
        pass
    return 'UNKNOWN', 'Complete a current manual check or obtain a documented exception'


def probe(control, policy):
    if control == 'os':
        code, value, _ = command(['/usr/bin/sw_vers', '-productVersion'])
        try:
            major = int(value.split('.')[0])
            return ('PASS' if not code and policy['minimum_major'] <= major <= policy['maximum_major'] else 'FAIL',
                    'OS compared with the configured range' if not code else 'OS inspection failed')
        except ValueError:
            return 'UNKNOWN', 'OS inspection failed'
    if control == 'standard-user':
        code, out, _ = command(['/usr/bin/id', '-Gn'])
        return ('UNKNOWN' if code else 'FAIL' if 'admin' in out.split() else 'PASS', 'Daily account privilege inspection')
    args, expected = {
        'filevault': (['/usr/bin/fdesetup', 'status'], 'FileVault is On'),
        'gatekeeper': (['/usr/sbin/spctl', '--status'], 'assessments enabled'),
        'firewall': (['/usr/libexec/ApplicationFirewall/socketfilterfw', '--getglobalstate'], 'State = 1'),
        'sip': (['/usr/bin/csrutil', 'status'], 'System Integrity Protection status: enabled'),
        'enrollment': (['/usr/bin/profiles', 'status', '-type', 'enrollment'], 'MDM enrollment: Yes'),
    }[control]
    code, out, err = command(args)
    return ('UNKNOWN' if code else 'PASS' if expected in out + err else 'FAIL', 'Read-only local state observation')


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def endpoint(item):
    # No credentials, redirects or response bodies; never print URL/error text.
    request = urllib.request.Request(item['url'], method='HEAD')
    try:
        with urllib.request.build_opener(NoRedirect).open(request, timeout=10) as response:
            return 'PASS', 'HTTPS HEAD reachable; authenticated access still needs manual verification'
    except urllib.error.HTTPError as error:
        if error.code in (401, 403, 405):
            return 'PASS', 'TLS/HTTP reachable; authenticated access still needs manual verification'
        return 'UNKNOWN', 'HTTP response requires review; redirects are not followed'
    except (OSError, urllib.error.URLError, ValueError):
        return 'UNKNOWN', 'DNS, connection, proxy or TLS failed; use approved IT diagnostics'


def private_write(path, data):
    path = Path(path).absolute()
    if any(part.is_symlink() for part in (path, *path.parents)) or path.exists():
        raise ValueError('output must be a new regular path without symlink parents; retain previous evidence')
    path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    # Exclusive create: never overwrite an existing evidence or snapshot file.
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, 'w') as target:
        json.dump(data, target, indent=2)
        target.write('\n')


def snapshot(policy, binding):
    versions = {}
    for name, args in {
        'macos': ['/usr/bin/sw_vers', '-productVersion'],
        'build': ['/usr/bin/sw_vers', '-buildVersion'],
        'brew': ['brew', 'list', '--versions'], 'node': ['node', '--version'],
        'python': ['python3', '--version'], 'uv': ['uv', '--version'],
        'pnpm': ['pnpm', '--version'], 'git': ['git', '--version'],
    }.items():
        code, out, _ = command(args, 30)
        versions[name] = {'status': 'observed' if code == 0 else 'unknown', 'value': out if code == 0 else ''}
    return {'schema': 1, 'device': binding, 'policy_sha256': fingerprint(policy),
            'observed_at': dt.datetime.now(dt.timezone.utc).isoformat().replace('+00:00', 'Z'), 'versions': versions}


def software_inventory(policy):
    catalogue = Path(__file__).resolve().parents[2] / 'config/applications.tsv'
    rows = []
    for line in catalogue.read_text().splitlines():
        if not line or line.startswith('#'):
            continue
        fields = line.split('\t')
        if fields[5] != 'app':
            continue
        app_id, expected, bundle = fields[0], Path(fields[6]), fields[7]
        candidates = [expected, Path.home() / 'Applications' / expected.name]
        locations = [item for item in candidates if item.exists()]
        for app in locations:
            row = {'application': app_id, 'path': str(app), 'status': 'UNKNOWN', 'policy_approved': False}
            try:
                with (app / 'Contents/Info.plist').open('rb') as source:
                    info = plistlib.load(source)
                row['bundle_id'] = info.get('CFBundleIdentifier', '')
                row['version'] = str(info.get('CFBundleShortVersionString', ''))
                verify, _, _ = command(['/usr/bin/codesign', '--verify', '--deep', '--strict', str(app)], 30)
                detail_code, _, details = command(['/usr/bin/codesign', '-dv', '--verbose=4', str(app)])
                team = re.search(r'^TeamIdentifier=([A-Za-z0-9]+)$', details, re.M)
                cdhash = re.search(r'^CDHash=([a-fA-F0-9]+)$', details, re.M)
                row['team_id'] = team[1] if team else ''
                row['cdhash'] = cdhash[1] if cdhash else ''
                row['signature'] = 'verified' if verify == 0 and detail_code == 0 else 'unverified'
                assessment, _, _ = command(['/usr/sbin/spctl', '--assess', '--type', 'execute', str(app)], 30)
                row['gatekeeper'] = 'accepted' if assessment == 0 else 'unconfirmed'
                executable = info.get('CFBundleExecutable', '')
                if not isinstance(executable, str) or Path(executable).name != executable:
                    raise ValueError('invalid bundle executable')
                arch_code, arches, _ = command(['/usr/bin/lipo', '-archs', str(app/'Contents/MacOS'/executable)])
                row['native_arm64'] = arch_code == 0 and 'arm64' in arches.split()
                identity = bundle == '-' or bundle == row['bundle_id']
                row['status'] = 'PASS' if identity and verify == 0 and assessment == 0 and row['native_arm64'] else 'REVIEW'
                approved = policy.get('software', {}).get(app_id, {})
                row['policy_approved'] = bool(row['status'] == 'PASS' and row['team_id'] and
                    row['team_id'] == approved.get('team_id') and row['bundle_id'] == approved.get('bundle_id') and
                    row['version'] in approved.get('versions', []))
            except (OSError, ValueError, plistlib.InvalidFileException, TypeError):
                pass
            rows.append(row)
    return rows


def benchmark_shell(shell):
    if shell not in ('/bin/zsh', '/opt/homebrew/bin/zsh'):
        raise ValueError('benchmark needs an approved zsh path')
    samples = []
    for _ in range(20):
        start = time.perf_counter()
        code, _, _ = command([shell, '+m', '-lic', 'exit'], 5)
        if code:
            raise ValueError('shell startup failed')
        samples.append(time.perf_counter() - start)
    return {'schema': 1, 'scope': '20 real interactive login-shell launches; startup files execute',
        'shell': shell, 'samples_seconds': samples, 'p50_seconds': statistics.median(samples),
        'p95_seconds': sorted(samples)[18], 'first_seconds': samples[0]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    actions = parser.add_mutually_exclusive_group(required=True)
    actions.add_argument('--plan', action='store_true')
    actions.add_argument('--check', action='store_true')
    actions.add_argument('--preflight', action='store_true')
    actions.add_argument('--init-evidence', metavar='NEW_PATH')
    actions.add_argument('--snapshot', metavar='NEW_PATH')
    actions.add_argument('--compare', metavar='SNAPSHOT')
    actions.add_argument('--software-inventory', metavar='NEW_PATH')
    actions.add_argument('--benchmark-shell', metavar='NEW_PATH')
    parser.add_argument('--shell', choices=['/bin/zsh', '/opt/homebrew/bin/zsh'], default='/bin/zsh')
    parser.add_argument('--mode', choices=['personal', 'managed'], default='personal')
    parser.add_argument('--policy')
    parser.add_argument('--evidence')
    parser.add_argument('--json', action='store_true')
    args = parser.parse_args()
    try:
        policy = policy_for(args)
        required = policy['required']
        if args.plan:
            print(json.dumps({'baseline': policy['baseline'], 'policy_sha256': fingerprint(policy),
                              'controls': {x: CONTROLS[x] for x in required},
                              'scope': 'Plan only; nothing probed or saved'}, indent=2))
            return 0
        binding = device()
        if args.init_evidence:
            private_write(args.init_evidence, {'schema': 1, 'device': binding, 'policy_sha256': fingerprint(policy),
                'controls': {key: {'status': 'unknown', 'checked_at': '', 'expires_at': '',
                    'reviewer_reference': '', 'evidence_reference': '', 'reason': '', 'approval_reference': ''}
                    for key in required}})
            print('Created private evidence template. No control was marked passed.')
            return 0
        if args.software_inventory:
            private_write(args.software_inventory, {'schema': 1, 'device': binding,
                'policy_sha256': fingerprint(policy), 'applications': software_inventory(policy),
                'scope': 'Observed signatures/architecture/versions; licenses, CLIs and first launch need manual evidence'})
            print('Created private application inventory; unapproved/unknown publishers remain unapproved.')
            return 0
        if args.benchmark_shell:
            private_write(args.benchmark_shell, {**benchmark_shell(args.shell), 'device': binding,
                'observed_at': dt.datetime.now(dt.timezone.utc).isoformat().replace('+00:00', 'Z')})
            print('Recorded shell timings; compare on the same hardware and OS before claiming improvement.')
            return 0
        if args.snapshot or args.compare:
            data = snapshot(policy, binding)
            if args.snapshot:
                private_write(args.snapshot, data)
                print('Created private observed-version snapshot; unknown versions remain unknown.')
                return 0
            previous = load(args.compare)
            differences = [key for key, value in data['versions'].items()
                           if previous.get('versions', {}).get(key) != value or value['status'] != 'observed']
            if previous.get('policy_sha256') != fingerprint(policy):
                differences.append('policy')
            print(json.dumps({'differences_or_unknown': differences, 'identical_observations': not differences}))
            return 1 if differences else 0
        evidence = load(args.evidence) if args.evidence and Path(args.evidence).exists() else {}
        if not isinstance(evidence, dict) or not isinstance(evidence.get('controls', {}), dict):
            raise ValueError('invalid evidence object')
        now = dt.datetime.now(dt.timezone.utc)
        rows = []
        for control in required:
            if args.preflight and control not in PREFLIGHT:
                continue
            result, detail = probe(control, policy) if control in AUTO else manual(control, evidence, policy, binding, now)
            # An observed failure cannot be overwritten with a claimed PASS.
            if result in ('FAIL', 'UNKNOWN') and control in AUTO:
                status, note = manual(control, evidence, policy, binding, now)
                if status == 'EXCEPTION':
                    result, detail = status, note
            rows.append({'control': control, 'result': result, 'detail': detail})
        if not args.preflight:
            if policy.get('software'):
                observed = software_inventory(policy)
                for app_id in policy['software']:
                    matches = [row for row in observed if row['application'] == app_id]
                    approved = len(matches) == 1 and matches[0]['policy_approved']
                    rows.append({'control': 'publisher-' + app_id, 'result': 'PASS' if approved else 'FAIL',
                                 'detail': 'Current publisher, bundle, architecture and allowed version observation'})
            for item in policy.get('endpoints', []):
                result, detail = endpoint(item)
                rows.append({'control': 'network-' + item['id'], 'result': result, 'detail': detail})
        ready = all(row['result'] in ('PASS', 'PASS-MANUAL', 'EXCEPTION') for row in rows)
        result = {'schema': 1, 'mode': args.mode, 'baseline': policy['baseline'], 'policy_sha256': fingerprint(policy),
                  'scope': 'preflight only' if args.preflight else 'local observations and operator attestations',
                  'ready': ready, 'controls': rows}
        if args.json:
            print(json.dumps(result, indent=2))
        else:
            print('Workstation readiness: ' + result['scope'])
            for row in rows:
                print(f"{row['result']}: {row['control']} — {row['detail']}")
            print('No independent compliance certification. Required unknown/failed controls block completion.')
        return 0 if ready else 10
    except (OSError, ValueError, TypeError, KeyError, AttributeError, subprocess.TimeoutExpired):
        print('BLOCKED: invalid/unapproved policy, unreadable evidence, unsupported input or unavailable device binding. No readiness claimed.', file=sys.stderr)
        return 2


if __name__ == '__main__':
    sys.exit(main())
