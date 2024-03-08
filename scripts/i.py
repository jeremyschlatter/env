import itertools
import json
import os
import subprocess
import sys

from pathlib import Path

targets = list(filter(
    lambda x: x[1]['storePaths'][0].endswith('-bundled-environment'),
    enumerate(json.loads(subprocess.check_output(
        ['nix', 'profile', 'list', '--json']
    ).decode())['elements']),
))

if len(targets) != 1:
    print(
        'I need exactly one derivation called "bundled-environment" ' +
        'to be in `nix profile list`',
        file=sys.stderr,
    )
    sys.exit(1)

(index, pkg) = targets[0]
flake = pkg['url']


def flatten(x):
    return [item for sublist in x for item in sublist]


inputs = flatten(zip(
    itertools.repeat('--update-input'),
    json.loads(
        subprocess.check_output([
            'nix', 'flake', 'metadata', '--json', flake,
        ]))['locks']['nodes']['root']['inputs'].keys(),
))

if os.getenv('I_DOT_PY_DO_FULL_UPDATE'):
    subprocess.check_call(
        ['nix', 'flake', 'update'],
        cwd=(Path.home() / 'nix' / 'public-base'),
    )

subprocess.check_call(['nix', 'profile', 'upgrade'] + inputs + [str(index)])

subprocess.check_call(['_jeremy-post-install'])
