import os.path
from subprocess import check_call

jj = os.path.exists('.jj')
git = os.path.exists('.git')

if not (jj or git):
    # We could run git init automatically, but this kind of serves as
    # a check that we are in the correct directory.
    # (I accidentally ran this command in my home dir once.)
    raise Exception(
        'Not a git directory. Run \'git init\' (or \'jj init\') first.'
    )

message = 'add nix flake direnv config'

if jj:
    check_call(['jj', 'new', '-m', message])


def write(path, txt):
    if os.path.exists(path):
        print(f'{path} already exists, skipping it')
        return
    print(f'Creating {path}')
    with open(path, 'w') as f:
        f.write(txt.lstrip())


write('.envrc', '''
export PROJECT_ROOT=$(expand_path .)
use flake
''')

# TODO: duplicated in remote-flake.py
write('flake.nix', '''
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

if git:
    print('Running `git add flake.nix`')
    check_call(['git', 'add', 'flake.nix'])

print('Running `direnv allow`')
check_call(['direnv', 'allow'])
check_call(['direnv', 'reload'])

if git:
    print('Running `git commit`')
    check_call(['git', 'add', '.envrc'])
    check_call([
        'git', 'commit',
        '.envrc', 'flake.nix', 'flake.lock',
        '-m', message,
    ])
if jj:
    print('Running `jj new`')
    check_call(['jj', 'new'])

print('Done.')
