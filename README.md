# My development environment

To use, first install [nix](https://nixos.org/nix/):

    curl https://nixos.org/nix/install | sh

Then use nix-env to install the rest:

    NIXPKGS_ALLOW_UNFREE=1 nix-env -rif https://github.com/jeremyschlatter/nixpkgs/tarball/master?$(date +%s)

(the query string at the end prevents caching)

To update, just re-run the last command.
