set -e
nix profile upgrade --recreate-lock-file 1
jeremy-post-install
