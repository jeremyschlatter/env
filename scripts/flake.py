import os.path
import subprocess


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
    nixpkgs.url = github:NixOS/nixpkgs/release-22.11;
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
''')  # noqa: E501

print('Running `direnv allow`')
subprocess.check_call(['direnv', 'allow'])
subprocess.check_call(['direnv', 'exec', '.', 'true'])

print('Done.')
