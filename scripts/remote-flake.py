import os
import sys
from pathlib import Path
from subprocess import check_call


def fail(msg: str):
    print(msg, file=sys.stderr)
    sys.exit(1)


my_flakes = Path.home() / 'src/my/flakes'
try:
    [_, flake_name] = sys.argv
except ValueError:
    fail(f'Usage: remote-flake <name>\n\n(flakes are stored in {my_flakes})')

flake_dir = my_flakes / flake_name
try:
    flake_dir.mkdir(parents=True)
except FileExistsError:
    fail(f'"{flake_name}" is already taken')


def write(path, txt):
    if os.path.exists(path):
        print(f'{path} already exists, skipping it')
        return
    print(f'Creating {path}')
    with open(path, 'w') as f:
        f.write(txt.lstrip())


# TODO: duplicated in flake.py
write(flake_dir / 'flake.nix', '''
{
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixpkgs-unstable;
    flake-utils.url = github:numtide/flake-utils;
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
    with nixpkgs.legacyPackages.${system};
    let
      scripts = {};
    in {
      devShell = mkShellNoCC {
        packages = lib.attrsets.mapAttrsToList writeShellScriptBin scripts ++ [
        ];
      };
    });
}
''')  # noqa: E501


def remote_git(*args):
    check_call(('git', '-C', flake_dir) + args)


remote_git('add', 'flake.nix')
remote_git('commit', '-m', f'add flake: {flake_name}')
remote_git('push')

write('.envrc', f'''
use flake {flake_dir}
''')

check_call(['direnv', 'allow'])
check_call(['direnv', 'reload'])
