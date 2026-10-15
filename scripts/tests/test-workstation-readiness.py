#!/usr/bin/env python3
import copy
import datetime as dt
import importlib.util
import json
import io
import plistlib
import sys
import subprocess
from unittest.mock import patch
from contextlib import redirect_stdout
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest

ROOT = Path(__file__).resolve().parents[2]

def module(name, file):
    spec = importlib.util.spec_from_file_location(name, ROOT / 'scripts/lib' / file)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result

editor = module('editor', 'editor-settings.py')
ready = module('ready', 'workstation-readiness.py')

class ReadinessTests(unittest.TestCase):
    def setUp(self):
        self.policy = ready.policy_for(SimpleNamespace(policy=None, mode='personal'))
        self.now = dt.datetime.now(dt.timezone.utc)
        self.evidence = {'schema': 1, 'device': 'fixture', 'policy_sha256': ready.fingerprint(self.policy), 'controls': {
            'recovery': {'status': 'pass', 'checked_at': (self.now-dt.timedelta(hours=1)).isoformat().replace('+00:00', 'Z'),
                'expires_at': (self.now+dt.timedelta(hours=1)).isoformat().replace('+00:00', 'Z'),
                'reviewer_reference': 'fixture-review', 'evidence_reference': 'fixture-drill'}}}

    def result(self, evidence):
        return ready.manual('recovery', evidence, self.policy, 'fixture', self.now)[0]

    def test_current_attestation_and_explicit_exception(self):
        self.assertEqual(self.result(self.evidence), 'PASS-MANUAL')
        record = self.evidence['controls']['recovery']
        record.update(status='exception', reason='fixture only', approval_reference='fixture approval')
        self.assertEqual(self.result(self.evidence), 'EXCEPTION')

    def test_evidence_fails_closed(self):
        for key, value in [('device', 'different'), ('policy_sha256', 'different'), ('schema', 2)]:
            evidence = copy.deepcopy(self.evidence); evidence[key] = value
            self.assertEqual(self.result(evidence), 'UNKNOWN')
        for key, value in [('checked_at', '2099-01-01T00:00:00Z'), ('expires_at', '2000-01-01T00:00:00Z'),
                           ('reviewer_reference', ''), ('evidence_reference', ''), ('status', 'unknown')]:
            evidence = copy.deepcopy(self.evidence); evidence['controls']['recovery'][key] = value
            self.assertEqual(self.result(evidence), 'UNKNOWN')

    def test_managed_template_is_not_approved(self):
        with self.assertRaises(ValueError):
            ready.policy_for(SimpleNamespace(policy=ROOT/'config/managed-policy.example.json', mode='managed'))

    def test_policy_cannot_remove_controls_or_accept_credential_urls(self):
        with tempfile.TemporaryDirectory() as temp:
            target=Path(temp)/'policy.json'
            for edit in [{'required': ['os']}, {'endpoints': [{'id':'test','url':'https://user:secret@example.test/'}]},
                         {'max_evidence_hours': 99999}]:
                policy={**self.policy, **edit}; target.write_text(json.dumps(policy))
                with self.assertRaises(ValueError):
                    ready.policy_for(SimpleNamespace(policy=target, mode='personal'))

    def test_probe_failure_is_unknown(self):
        original = ready.command
        try:
            ready.command = lambda args, timeout=15: (1, '', '')
            self.assertEqual(ready.probe('firewall', self.policy)[0], 'UNKNOWN')
            ready.command = lambda args, timeout=15: (0, 'Firewall is disabled. (State = 0)', '')
            self.assertEqual(ready.probe('firewall', self.policy)[0], 'FAIL')
        finally:
            ready.command = original

    def test_private_outputs_refuse_overwrite_and_symlinks(self):
        with tempfile.TemporaryDirectory() as temp:
            target=Path(temp).resolve()/'evidence.json'; ready.private_write(target, {})
            self.assertEqual(target.stat().st_mode & 0o777, 0o600)
            with self.assertRaises(ValueError): ready.private_write(target, {})
            link=target.parent/'link'; link.symlink_to(target)
            with self.assertRaises(ValueError): ready.private_write(link, {})

    def test_jsonc_comments_trailing_commas_strings_duplicates(self):
        parsed=editor.read_jsonc('{// comment\n"a": false, "url": "https://host/*text*/,}",}')
        self.assertIs(parsed['a'], False)
        self.assertEqual(parsed['url'], 'https://host/*text*/,}')
        for text in ['{"a":false,"a":true}', '{/* never closed', '{"a":NaN}', '{"a":false,,}']:
            with self.assertRaises(ValueError): editor.read_jsonc(text)

    def test_cli_cannot_pass_without_current_manual_evidence(self):
        with tempfile.TemporaryDirectory() as temp:
            evidence = Path(temp)/'evidence.json'
            args = ['readiness', '--check', '--json', '--evidence', str(evidence)]
            with patch.object(sys, 'argv', args), patch.object(ready, 'device', return_value='fixture'), \
                 patch.object(ready, 'probe', return_value=('PASS', 'fixture')):
                with redirect_stdout(io.StringIO()) as output:
                    self.assertEqual(ready.main(), 10)
                self.assertFalse(json.loads(output.getvalue())['ready'])
                evidence.write_text(json.dumps(self.evidence))
                with redirect_stdout(io.StringIO()) as output:
                    self.assertEqual(ready.main(), 0)
                self.assertTrue(json.loads(output.getvalue())['ready'])
                self.assertIn('PASS-MANUAL', output.getvalue())

    def test_device_binding_changes_when_account_is_recreated(self):
        def commands(args, timeout=15):
            if args[0].endswith('ioreg'):
                return 0, '\"IOPlatformUUID\" = \"ABC-123\"', ''
            return 0, 'GeneratedUID: ' + account[0], ''
        account = ['AAA-111']
        with patch.object(ready, 'command', side_effect=commands), \
             patch.object(ready.pwd, 'getpwuid', return_value=SimpleNamespace(pw_name='fixture')):
            first = ready.device()
            account[0] = 'BBB-222'
            self.assertNotEqual(first, ready.device())

    def test_exceptions_cannot_bypass_required_encryption_and_gatekeeper(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp)/'evidence.json'
            for control in ('filevault', 'gatekeeper', 'firewall'):
                evidence = copy.deepcopy(self.evidence)
                evidence['controls'][control] = {
                    **evidence['controls']['recovery'], 'status': 'exception',
                    'reason': 'reviewed fixture', 'approval_reference': 'fixture approval'}
                target.write_text(json.dumps(evidence))
                for observed in ('FAIL', 'UNKNOWN'):
                    with self.subTest(control=control, observed=observed), \
                         patch.object(sys, 'argv', ['readiness', '--check', '--json', '--evidence', str(target)]), \
                         patch.object(ready, 'device', return_value='fixture'), \
                         patch.object(ready, 'probe', side_effect=lambda key, policy: (observed if key == control else 'PASS', 'fixture')):
                        with redirect_stdout(io.StringIO()) as output:
                            self.assertEqual(ready.main(), 0 if control == 'firewall' else 10)
                        report = json.loads(output.getvalue())
                        result = next(row['result'] for row in report['controls'] if row['control'] == control)
                        self.assertEqual(result, 'EXCEPTION' if control == 'firewall' else observed)

    def test_publisher_observation_never_approves_wrong_or_invalid_signature(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp); app = root/'Fixture Publisher.app'
            (app/'Contents/MacOS').mkdir(parents=True)
            (root/'config').mkdir()
            (root/'config/applications.tsv').write_text('fixture\trequired\t04\tFixture\tfixture\tapp\t'+str(app)+'\tcom.example.fixture\t-\n')
            with (app/'Contents/Info.plist').open('wb') as target:
                plistlib.dump({'CFBundleIdentifier':'com.example.fixture','CFBundleShortVersionString':'1.0','CFBundleExecutable':'fixture'},target)
            valid = [True]
            def commands(args, timeout=15):
                if '--verify' in args: return (0 if valid[0] else 1), '', ''
                if '-dv' in args: return 0, '', 'TeamIdentifier=TEAM123\nCDHash=abcdef\n'
                if '-archs' in args: return 0, 'arm64 x86_64', ''
                return 0, '', ''
            policy = {'software': {'fixture': {'team_id':'TEAM123','bundle_id':'com.example.fixture','versions':['1.0']}}}
            with patch.object(ready, '__file__', str(root/'scripts/lib/workstation-readiness.py')), \
                 patch.object(ready, 'command', side_effect=commands):
                self.assertTrue(ready.software_inventory(policy)[0]['policy_approved'])
                policy['software']['fixture']['team_id']='WRONG'
                self.assertFalse(ready.software_inventory(policy)[0]['policy_approved'])
                policy['software']['fixture']['team_id']='TEAM123'; valid[0]=False
                self.assertFalse(ready.software_inventory(policy)[0]['policy_approved'])

    def test_release_draft_and_candidate_validation_order(self):
        config=json.loads((ROOT/'release-please-config.json').read_text())
        self.assertTrue(config['draft']); self.assertTrue(config['force-tag-creation'])
        workflow=(ROOT/'.github/workflows/release.yml').read_text()
        self.assertLess(workflow.index('Validate the candidate before publication'), workflow.index('Build verified runtime assets'))
        self.assertLess(workflow.index('scripts/tests/test-packaged-modules.sh'), workflow.index('--draft=false'))
        self.assertIn('ref: ${{ steps.candidate.outputs.sha }}', workflow)
        self.assertGreaterEqual(workflow.count('test "$(git rev-parse'), 3)

    def test_aggregate_ci_gate_blocks_unsuccessful_platform_results(self):
        workflow = (ROOT/'.github/workflows/validate.yml').read_text()
        aggregate = workflow.split('\n  validate:\n', 1)[1]
        self.assertIn('name: validate', aggregate)
        self.assertIn('needs: platform', aggregate)
        self.assertIn('if: ${{ always() }}', aggregate)
        self.assertIn('PLATFORM_RESULT: ${{ needs.platform.result }}', aggregate)
        self.assertIn('os: [macos-15, macos-26]', workflow)
        gate = next(line.split('run: ', 1)[1] for line in aggregate.splitlines() if 'run: ' in line)
        for status in ('success', 'failure', 'cancelled', 'skipped', ''):
            with self.subTest(status=status):
                result = subprocess.run(['/bin/bash', '-c', gate], env={'PLATFORM_RESULT': status}, check=False)
                self.assertEqual(result.returncode == 0, status == 'success')

if __name__ == '__main__': unittest.main()
