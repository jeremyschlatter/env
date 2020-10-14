# {"deps": ["gitAndTools.hub"], "requirements": ["click"]} #nix
from pathlib import Path
from subprocess import run
import sys

import click

@click.command()
@click.argument('repo')
def main(repo: str):
    dest = Path.home() / 'src' / 'github.com' / Path(repo)
    if not dest.is_dir():
        dest.parent.mkdir(exist_ok=True)
        if run(['hub', 'clone', repo, dest]).returncode:
            sys.exit(1)
    print('cd', dest)

if __name__ == '__main__':
    main()
