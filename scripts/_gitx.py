# {"deps": ["git"]} #nix
from pathlib import Path
from subprocess import run, PIPE
import sys

if len(sys.argv) != 3 or sys.argv[1] not in ["github", "gitlab"]:
    print('usage: _gitx {github|gitlab} <user/repo>', file=sys.stderr)
    sys.exit(1)

host, repo = sys.argv[1:]
dest = Path.home() / 'src' / f'{host}.com' / Path(repo)


# NOTE: We are wrapped by a shell function that evals our stdout, eg
#   clone() { eval "$(_gitx github $1)"; }
# So stdout is reserved for the final `cd` line. Everything else -- our
# own messages and all git output -- goes to stderr.
def git(*args, **kwargs):
    return run(['git', *args], stdout=sys.stderr, **kwargs)


def say(msg):
    print(f'_gitx: {dest}: {msg}', file=sys.stderr)


if not dest.is_dir():
    dest.parent.mkdir(parents=True, exist_ok=True)
    if git('clone', f'git@{host}.com:{repo}.git', dest).returncode:
        sys.exit(1)
else:
    def read(*args):
        cmd = ['git', '-C', dest, *args]
        return run(cmd, stdout=PIPE, text=True).stdout.strip()

    if read('status', '--porcelain'):
        say('local changes, not pulling')
    else:
        # origin/HEAD may be unset (old clone) or stale (renamed branch).
        git('-C', dest, 'remote', 'set-head', 'origin', '--auto')
        head = read('symbolic-ref', '--short', 'refs/remotes/origin/HEAD')
        default = head.removeprefix('origin/')
        branch = read('symbolic-ref', '--short', '--quiet', 'HEAD')
        if branch != default:
            say(f'on {branch or "detached HEAD"}, not {default}, not pulling')
        elif git('-C', dest, 'pull', '--ff-only').returncode:
            sys.exit(1)

print('cd', dest)
