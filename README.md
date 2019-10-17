# My development environment

You don't need to clone this repo to use it.

To use, first install [nix](https://nixos.org/nix/):

    curl https://nixos.org/nix/install | sh

Then use nix-env to install the rest:

    NIXPKGS_ALLOW_UNFREE=1 nix-env -rif https://github.com/jeremyschlatter/nixpkgs/tarball/master
    
You can also pull my updates by re-running the above command.

The above command installs my custom shell as `shell`. To use that as your login shell, you can do:

    echo `which shell` | sudo tee -a /etc/shells && chsh -s `which shell`
    
...unless you are on NixOS, in which case you should instead set this in the system config:

    users.users.<user>.shell = "/home/<your username>/.nix-profile/bin/shell";
