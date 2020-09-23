# My development environment

**Usage**

_I am in the middle of converting this repo to use Nix flakes and so do not have reliable usage instructions right now_.

**About my environment**

This config installs [kitty](https://sw.kovidgoyal.net/kitty/), which I use as my terminal emulator.

It configures kitty to use a custom shell (bash with a custom bashrc). To use my shell config outside
kitty, you can run it manually as `shell`.

**Other Notes**

To pick up the Fira Code font in Gnome I made this symlink:

    ln -s ~/.flake/profile/share/fonts/ ~/.local/share/

To pick up application launchers for kitty and alacritty in Gnome I made this symlink:

    rmdir ~/.local/share/applications
    ln -s ~/.flake/profile/share/applications/ ~/.local/share/
