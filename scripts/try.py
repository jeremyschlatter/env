import subprocess
import sys

subprocess.run(
    ['nix', 'shell'] +
    [f'nixpkgs#{pkg}' for pkg in sys.argv[1:]]
)
