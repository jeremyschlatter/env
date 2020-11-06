# {"requirements": ["click"]} #nix
'''Toggle the name of the .git folder in a git repo.

When git folders get large, "git status" gets very slow.

My prompt calls "git status", so in large directories _every command I run_ is
slowed down by this.

Renaming the .git folder is a quick hack to work around this.
'''

from click import command, option
from pathlib import Path
from sys import exit, stderr

def fail(s):
    print(s, file=stderr)
    exit(1)

@command()
@option('--regit', is_flag=True)
def main(regit):
    root = Path.cwd()
    while not any((root / p).exists() for p in ['.git', 'dot-git']):
        if root.parent == root:
            fail('no .git or dot-git folder found')
        root = root.parent
    src = root / '.git'
    dst = root / 'dot-git'
    if regit:
        src, dst = dst, src
    if dst.exists():
        fail(f'{dst} already exists')
    src.rename(dst)

if __name__ == '__main__':
    main()
