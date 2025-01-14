# {"deps": ["git"], "requirements": ["sh"]} #nix
import json
import os
import sys

import sh


def fail(s):
    print(s, file=sys.stderr)
    sys.exit(1)


def read_metadata():
    profile = sh.nix('profile', 'list', '--json')
    targets = []
    for k, v in json.loads(profile)['elements'].items():
        for p in v['storePaths']:
            if p.endswith('-bundled-environment'):
                targets += [(k, v['originalUrl'])]
                break

    if len(targets) != 1:
        fail(
            'I need exactly one derivation with a "bundled-environment" ' +
            'store path to be in `nix profile list`',
        )

    return targets[0]


(package_name, flake_path) = read_metadata()

output = sh.nix(
    ['flake', 'update', '--flake', flake_path, '--commit-lock-file'] +
    ([] if os.getenv('I_DOT_PY_DO_FULL_UPDATE') else ['public-base']),
    _out=sys.stdout,
    _tee=True,
)

if 'will not write lock file of flake' in output:
    fail('check in your changes!')

boop = {
    '_in': sys.stdin,
    '_out': sys.stdout,
    '_err': sys.stderr,
}

sh.nix('profile', 'upgrade', package_name, **boop)
sh.Command('_jeremy-post-install')(**boop)
