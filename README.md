# My development environment

To use, first install [nix](https://nixos.org/nix/):

    curl https://nixos.org/nix/install | sh

Then use nix-env to install the rest:

    NIXPKGS_ALLOW_UNFREE=1 nix-env -rif https://github.com/jeremyschlatter/nixpkgs/tarball/master
    
You can also pull my updates by re-running the above command.

Run `shell` to use the custom shell.

To use `shell` as your login shell, something like the following should work:

    echo `which shell` | sudo tee -a /etc/shells && chsh -s `which shell`
    
On NixOS, you should instead set this in the system config:

    users.users.<user>.shell = "/home/<your username>/.nix-profile/bin/shell";
