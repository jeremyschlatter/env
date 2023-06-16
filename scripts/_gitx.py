# {"deps": ["git"]} #nix
from pathlib import Path
from subprocess import run
import sys

if len(sys.argv) != 3 or sys.argv[1] not in ["github", "gitlab"]:
    print('usage: _gitx {github|gitlab} <user/repo>', file=sys.stderr)
    sys.exit(1)

host, repo = sys.argv[1:]
dest = Path.home() / 'src' / f'{host}.com' / Path(repo)
if not dest.is_dir():
    dest.parent.mkdir(parents=True, exist_ok=True)
    if run(['git', 'clone', f'git@{host}.com:{repo}.git', dest]).returncode:
        sys.exit(1)
print('cd', dest)
