# {"deps": ["nix_2_4"]} #nix
import itertools
import json
import os
import subprocess
import sys

targets = list(filter(lambda s: s.endswith('-bundled-environment'),
    subprocess.check_output(['nix', 'profile', 'list']).decode().strip().split('\n')))

if len(targets) != 1:
    print('I need exactly one derivation called "bundled-environment" to be in `nix profile list`', file=sys.stderr)
    sys.exit(1)

index  = targets[0].split()[0]
flake  = targets[0].split()[1].split('#')[0]

def flatten(l):
    return [item for sublist in l for item in sublist]

if os.getenv('I_DOT_PY_DO_FULL_UPDATE'):
    inputs = ['--recreate-lock-file']
else:
    inputs = flatten(zip(
        itertools.repeat('--update-input'),
        json.loads(
            subprocess.check_output([
                'nix', 'flake', 'metadata', '--json', flake,
        ]))['locks']['nodes']['root']['inputs'].keys(),
    ))

subprocess.check_call(['nix', 'profile', 'upgrade'] + inputs + [index])
subprocess.check_call(['jeremy-post-install'])
