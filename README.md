# My development environment

To use, first install [nix](https://nixos.org/nix/):

    $ curl https://nixos.org/nix/install | sh

Set `allowUnfree = true;` in config.nix.

    $ mkdir -p ~/.config/nixpkgs && echo "{ allowUnfree = true; }" > ~/.config/nixpkgs/config.nix

Then use nix-env to install the rest:

    $ nix-env -rif https://github.com/jeremyschlatter/nixpkgs/tarball/master?$(date +%s)

(the query string at the end prevents caching)
