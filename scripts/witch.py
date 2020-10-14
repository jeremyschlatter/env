# {"deps": ["entr"], "requirements": ["termcolor"]} #nix
from subprocess import run
import glob
import sys

from termcolor import cprint

do_client_mode = 'WITCH_CLIENT_MODE'
argv = sys.argv

def main():
    try:
        if len(argv) > 2 and argv[1] == do_client_mode:
            client_mode(argv[2:])
        else:
            entr_mode()
    except KeyboardInterrupt:
        pass

def entr_mode():
    if len(argv) < 3:
        print('usage: witch <glob> <command> [args...]', file=sys.stderr)
        sys.exit(1)
    self, path_glob, command = argv[0], argv[1], argv[2:]
    entr = run(
        ['entr', '-c', sys.executable, self, do_client_mode] + command,
        input='\n'.join(glob.glob(path_glob, recursive=True)).encode(),
    )
    if entr.returncode != 0:
        sys.exit(entr.returncode)

def client_mode(cmd):
    code = run(cmd).returncode
    if code == 0:
        cprint('ok', 'green')
    else:
        cprint('failed', 'red')
        sys.exit(code)

if __name__ == '__main__':
    main()
