# {"deps": ["git"]} #nix
from pathlib import Path
from subprocess import run
import sys

if len(sys.argv) != 2:
    print('usage: github <user/repo>', file=sys.stderr)
    sys.exit(1)

repo = sys.argv[1]
dest = Path.home() / 'src' / 'github.com' / Path(repo)
if not dest.is_dir():
    dest.parent.mkdir(parents=True, exist_ok=True)
    if run(['git', 'clone', f'git@github.com:{repo}.git', dest]).returncode:
        sys.exit(1)
print('cd', dest)
