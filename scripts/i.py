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
            'nix', 'flake', 'metadata', '--json', target['flake'],
    ]))['locks']['nodes']['root']['inputs'].keys(),
))

subprocess.check_call(['nix', 'profile', 'upgrade'] + inputs + ['1'])
subprocess.check_call(['jeremy-post-install'])
