# {"deps": ["coreutils", "gnutar"]} #nix
import subprocess
import sys
from pathlib import Path


def parse_path(p):
    """Parse path, returning (sprite_name, path) or (None, path) for local."""
    if ':' in p and not p.startswith('/') and not p.startswith('.'):
        sprite, path = p.split(':', 1)
        return sprite, path
    return None, p


def run(cmd, stdin=None, capture=True):
    r = subprocess.run(cmd, input=stdin, capture_output=capture)
    if r.returncode != 0:
        if capture:
            sys.stderr.write(r.stderr.decode())
        sys.exit(r.returncode)
    return r.stdout if capture else None


def is_dir_remote(sprite, path):
    r = subprocess.run(
        ['sprite', '-s', sprite, 'exec', 'test', '-d', path],
        capture_output=True,
    )
    return r.returncode == 0


def copy_local_to_remote(local_path, sprite, remote_path):
    local = Path(local_path)
    if not local.exists():
        sys.exit(f"error: {local_path} does not exist")

    p = remote_path
    if local.is_dir():
        tar = run(['tar', '-C', str(local.parent), '-cf', '-', local.name])
        encoded = run(['base64'], stdin=tar)
        cmd = f'mkdir -p {p} && base64 -d | tar -C {p} -xf -'
        run(['sprite', '-s', sprite, 'exec', 'bash', '-c', cmd], stdin=encoded)
    else:
        encoded = run(['base64', str(local)])
        cmd = f'mkdir -p "$(dirname {p})" && base64 -d > {p}'
        run(['sprite', '-s', sprite, 'exec', 'bash', '-c', cmd], stdin=encoded)


def copy_remote_to_local(sprite, remote_path, local_path):
    local = Path(local_path)
    is_dir = is_dir_remote(sprite, remote_path)

    if is_dir:
        encoded = run(
            ['sprite', '-s', sprite, 'exec', 'bash', '-c',
             f'tar -C {remote_path} -cf - . | base64'],
        )
        tar = run(['base64', '-d'], stdin=encoded)
        local.mkdir(parents=True, exist_ok=True)
        run(['tar', '-C', str(local), '-xf', '-'], stdin=tar)
    else:
        encoded = run(
            ['sprite', '-s', sprite, 'exec', 'bash', '-c',
             f'base64 {remote_path}'],
        )
        decoded = run(['base64', '-d'], stdin=encoded)
        local.parent.mkdir(parents=True, exist_ok=True)
        local.write_bytes(decoded)


if len(sys.argv) != 3:
    print('usage: sprite-cp <source> <destination>', file=sys.stderr)
    print('  sprite-cp sprite-name:remote/path local/path', file=sys.stderr)
    print('  sprite-cp local/path sprite-name:remote/path', file=sys.stderr)
    sys.exit(1)

src_sprite, src_path = parse_path(sys.argv[1])
dst_sprite, dst_path = parse_path(sys.argv[2])

if src_sprite and dst_sprite:
    sys.exit("error: cannot copy between two sprites directly")
if not src_sprite and not dst_sprite:
    sys.exit("error: one path must be a sprite path (sprite-name:path)")

if src_sprite:
    copy_remote_to_local(src_sprite, src_path, dst_path)
else:
    copy_local_to_remote(src_path, dst_sprite, dst_path)
