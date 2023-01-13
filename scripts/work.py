import json
import os.path
import subprocess

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
        raise 'this script requires a "bundled-environment" to be installed'


def write(where, what):
    with open(where, 'w') as f:
        f.write(what.lstrip('\n'))


write('.envrc', '''
export PROJECT_ROOT=$(expand_path .)
use flake
''')

write('flake.nix', r'''
{
  description = "a project";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/NIX_RELEASE;
    flake-utils.url = github:numtide/flake-utils;
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
    with nixpkgs.legacyPackages.${system};
    with lib;
    let
      scripts = {};
    in {
      devShell = stdenvNoCC.mkDerivation {
        name = "shell";
        buildInputs = attrsets.mapAttrsToList writeShellScriptBin scripts ++ [
        ];
      };
    });
}
'''.replace('NIX_RELEASE', release))

subprocess.run(['vi', 'flake.nix'])
subprocess.check_call(['direnv', 'allow'])
