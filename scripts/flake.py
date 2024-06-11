import json
import os.path
import subprocess

if not os.path.exists('.git'):
    # We could run git init automatically, but this kind of serves as
    # a check that we are in the correct directory.
    # (I accidentally ran this command in my home dir once.)
    raise Exception('Not a git directory. Run \'git init\' first.')

# Look up the nix release used in the current environment on this machine.
# We'll use the same one in flake.nix.
with open(os.path.expandvars('$HOME/.nix-profile/manifest.json')) as f:
    for e in json.load(f)['elements']:
        if any(p.endswith('-bundled-environment') for p in e['storePaths']):
            release = json.loads(subprocess.check_output(
                ['nix', 'flake', 'metadata', '--json', e['originalUrl']]
            ))['locks']['nodes']['nixpkgs']['original']['ref']
            break
    else:
        raise Exception(
            'this script requires a "bundled-environment" to be installed'
        )


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

write('flake.nix', '''
{
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/NIX_RELEASE;
    flake-utils.url = github:numtide/flake-utils;
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
    with nixpkgs.legacyPackages.${system};
    let
      scripts = {};
    in {
      devShell = stdenvNoCC.mkDerivation {
        name = "shell";
        buildInputs = lib.attrsets.mapAttrsToList writeShellScriptBin scripts ++ [

        ];
      };
    });
}
'''.replace('NIX_RELEASE', release))  # noqa: E501

print('Running `git add flake.nix`')
subprocess.check_call(['git', 'add', 'flake.nix'])

print('Running `direnv allow`')
subprocess.check_call(['direnv', 'allow'])
subprocess.check_call(['direnv', 'exec', '.', 'true'])

print('Running `git commit`')
subprocess.check_call(['git', 'add', '.envrc'])
subprocess.check_call([
    'git', 'commit',
    '.envrc', 'flake.nix', 'flake.lock',
    '-m', 'add nix flake direnv config',
])

print('Done.')
