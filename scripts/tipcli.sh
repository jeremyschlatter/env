# {"deps": ["gh"]} #nix
#!/usr/bin/env bash
set -euo pipefail

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/tipcli"
BINARY="$CACHE_DIR/opcli"

if [[ "${1:-}" == "up" || "${1:-}" == "update" ]]; then
    mkdir -p "$CACHE_DIR"
    ARCH=$(uname -m)
    TARBALL="opcli-tip-darwin-${ARCH}.tar.gz"
    gh release download tip \
        --repo jeremyschlatter/opcli \
        --pattern "$TARBALL" \
        --dir "$CACHE_DIR" \
        --clobber
    tar -xzf "$CACHE_DIR/$TARBALL" -C "$CACHE_DIR"
    rm "$CACHE_DIR/$TARBALL"
    chmod +x "$BINARY"
    echo "Updated to: $(gh release view tip --repo jeremyschlatter/opcli --json body --jq '.body | match("Commit: ([a-f0-9]{8})") | .captures[0].string')"
    exit 0
fi

if [[ ! -x "$BINARY" ]]; then
    echo "No cached binary. Run 'tipcli update' first." >&2
    exit 1
fi

exec "$BINARY" "$@"
