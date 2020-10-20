# {"deps": ["nixFlakes"]} #nix
import itertools
import json
import os
import subprocess

with open(os.path.expanduser('~/nix/target')) as f:
    target = json.load(f)

def flatten(l):
    return [item for sublist in l for item in sublist]

inputs = flatten(zip(
    itertools.repeat('--update-input'),
    json.loads(
        subprocess.check_output([
            'nix', 'flake', 'list-inputs', '--json', target['flake'],
    ]))['nodes']['root']['inputs'].keys(),
))

subprocess.check_call(
    ['nix', 'build']
      + inputs
      # Don't try to write the lockfile if this is a remote derivation.
      + (['--no-write-lock-file'] if ':' in target['flake'] else [])
      + [
          '--no-link',
          '--profile', target['profile'],
          target['flake'],
        ],
)
subprocess.check_call(['jeremy-post-install'])
