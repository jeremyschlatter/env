import os
import subprocess
import sys

flake = 'nixpkgs'
if os.environ.get('UNFREE') == '1':
    flake = 'github:numtide/nixpkgs-unfree/nixpkgs-unstable'

subprocess.run(['nix', 'shell'] + [f'{flake}#{pkg}' for pkg in sys.argv[1:]])
