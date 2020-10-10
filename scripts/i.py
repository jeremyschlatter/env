import itertools
import json
import os
import subprocess

profile = os.path.expanduser('~/.flake')

with open(f'{profile}/drvpath') as f:
    drvpath = f.read().strip()

def flatten(l):
    return [item for sublist in l for item in sublist]

inputs = flatten(zip(
    itertools.repeat('--update-input'),
    json.loads(
        subprocess.check_output(['nix', 'flake', 'list-inputs', '--json', drvpath])
    )['nodes']['root']['inputs'].keys(),
))

subprocess.check_call(
    ['nix', 'build']
      + inputs
      # Don't try to write the lockfile if this is a remote derivation.
      + (['--no-write-lock-file'] if ':' in drvpath else [])
      + [
          '--no-link',
          '--profile', f'{profile}/profile',
          drvpath
        ],
)
subprocess.check_call(['jeremy-post-install'])
