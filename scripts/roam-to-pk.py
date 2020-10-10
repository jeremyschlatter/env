# {"deps": ["perkeep"]} #nix
import os
import os.path as path
import subprocess
import sys
import tempfile
import zipfile

from datetime import datetime

def plural(n):
    return '' if n == 1 else 's'

def main():
    downloads_dir = path.expanduser('~/Downloads')
    roam_backups = [
        path.join(downloads_dir, f) for f in os.listdir(downloads_dir) if f.startswith('Roam-Export-')
    ]
    if not roam_backups:
        print('No Roam backups found', file=sys.stderr)
        sys.exit(1)
    json_count = 0
    md_count = 0
    for f in roam_backups:
        with tempfile.TemporaryDirectory() as d:
            private = path.join(d, "private")
            os.mkdir(private)
            zipfile.ZipFile(f).extractall(private)
            if path.exists(path.join(private, "private.json")):
                json = True
                json_count += 1
            elif path.exists(path.join(private, 'TODO.md')):
                json = False
                md_count += 1
            else:
                print(f'Unrecognized backup: {f}', file=sys.stderr)
                sys.exit(1)
            which = 'json' if json else 'markdown'
            subprocess.check_call([
                'pk', 'put', 'file', '--permanode',
                '--title', f'Roam {datetime.now().isoformat(" ", timespec="minutes")} ({which})',
                "--tag", f'backup,roam,roam-to-pk,{which}',
                path.join(private, "private.json") if json else private,
            ])
            os.remove(f)
    print(f'Saved {json_count} json file{plural(json_count)} and {md_count} markdown archive{plural(md_count)}')

if __name__ == '__main__':
    main()
