#!/usr/bin/env python3
"""Exercise all 96 nominal base selections without installs or saved state."""
import itertools
import json
import os
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix='day-one-matrix-') as folder:
    state = Path(folder) / 'state with spaces é'
    env = {**os.environ, 'DAY_ONE_MAC_STATE_ROOT': str(state), 'DAY_ONE_MAC_STATE_DIR': str(state)}
    for track, stack, auth, preset in itertools.product(range(1, 5), ['node', 'python', 'both'],
                                                      ['1password', 'keychain', 'external', 'https'],
                                                      ['core', 'recommended-productivity']):
        args = [str(root/'scripts/setup.sh'), '--plan', '--json', '--track', str(track), '--stack', stack,
                '--auth-mode', auth, '--preset', preset, '--layout', 'none', '--ghq', 'no',
                '--dotfiles-versioning', 'none', '--shell', 'apple', '--prompt', 'none']
        result = subprocess.run(args, env=env, capture_output=True, text=True, timeout=20, check=True)
        data = json.loads(result.stdout)
        assert data['selection']['track'] == str(track)
        assert data['selection']['stack'] == stack
        assert data['selection']['auth_mode'] == auth
        assert data['selection']['preset'] == preset
        assert len(data['phases']) == 8
        assert not state.exists(), 'plan wrote state'
    print('PASS: 96 base selection plans; spaces/Unicode; no state mutation (not 96 live installations)')
