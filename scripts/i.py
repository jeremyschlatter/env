import json
import os
import sys

from subprocess import check_call, check_output


def read_metadata():
    profile = check_output(['nix', 'profile', 'list', '--json']).decode()
    targets = []
    for k, v in json.loads(profile)['elements'].items():
        for p in v['storePaths']:
            if p.endswith('-bundled-environment'):
                targets += [(k, v['originalUrl'])]
                break

    if len(targets) != 1:
        print(
            'I need exactly one derivation with a "bundled-environment" ' +
            'store path to be in `nix profile list`',
            file=sys.stderr,
        )
        sys.exit(1)

    return targets[0]


(package_name, flake_path) = read_metadata()

check_call(
    ['nix', 'flake', 'update', '--flake', flake_path, '--commit-lock-file'] +
    ([] if os.getenv('I_DOT_PY_DO_FULL_UPDATE') else ['public-base'])
)

check_call(['nix', 'profile', 'upgrade', package_name])
check_call(['_jeremy-post-install'])
