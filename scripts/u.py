# {"deps": ["nixFlakes"]} #nix
import json
import os
import subprocess

with open(os.path.expanduser('~/nix/target')) as f:
    target = json.load(f)

subprocess.check_call(
    ['nix', 'build']
      # Don't try to write the lockfile if this is a remote derivation.
      + (['--no-write-lock-file'] if ':' in target['flake'] else [])
      + [
          '--recreate-lock-file',
          '--no-link',
          '--profile', target['profile'],
          target['flake'],
        ],
)
subprocess.check_call(['jeremy-post-install'])
