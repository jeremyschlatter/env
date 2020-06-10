# My development environment

You don't need to clone this repo to use it.

To use, first install [nix](https://nixos.org/nix/):

    curl https://nixos.org/nix/install | sh

Then use nix-env to install the rest:

    nix-env -rif https://github.com/jeremyschlatter/nixpkgs/tarball/master

You can also pull my updates by re-running the above command.

**About my environment**

This config installs [kitty](https://sw.kovidgoyal.net/kitty/), which I use as my terminal emulator.

It configures kitty to use a custom shell (bash with a custom bashrc). To use my shell config outside
kitty, you can run it manually as `shell`.

**Other Notes**

To pick up the Fira Code font in Gnome I made this symlink:

    ln -s ~/.nix-profile/share/fonts/ ~/.local/share/

To pick up application launchers for kitty and alacritty in Gnome I made this symlink:

    rmdir ~/.local/share/applications
    ln -s ~/.nix-profile/share/applications/ ~/.local/share/

To pick up the Solarized theme for bat, I ran:

    bat cache --build
