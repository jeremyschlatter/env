# {"deps": ["gitAndTools.hub"], "requirements": ["click"]} #nix
from pathlib import Path
from subprocess import run
import sys

import click

@click.command()
@click.argument('github_repo')
def main(github_repo: str):
    org, repo = github_repo.split('/')
    base = Path.home() / 'src' / 'github.com' / org
    full = base / repo
    if not full.is_dir():
        base.mkdir()
        if run(['hub', 'clone', github_repo, full]).returncode:
            sys.exit(1)
    print('cd', full)

if __name__ == '__main__':
    main()
