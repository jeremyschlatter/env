# My development environment

**Overview**

I use the [nix](https://nixos.org/) package manager on all of my (non-mobile) computers, and it is very helpful.

There are many ways that this setup provides me value, but one of the most legible is this: I have a fairly customized environment (including a few dozen [tools](https://github.com/jeremyschlatter/nixpkgs/blob/c97e18297883df763df2326bcf8231d9bcd58f11/flake.nix#L164-L217), a couple hundred lines of [config](config), and about a dozen custom [scripts](scripts)) that **I am able to install and synchronize across multiple machines**, including my personal MacBook Pro, my Linux work machine, and a few servers I use for hobby projects.

**Usage**

1. [Install nix](https://nixos.org/download.html)
2. Upgrade nix to a pre-release version with experimental support for flakes:*

    `nix-env -iAf https://github.com/NixOS/nixpkgs/tarball/release-20.03 nixFlakes`

3. Enable experimental features:*

    `sudo mkdir -p /etc/nix && echo 'experimental-features = nix-command flakes ca-references' | sudo tee -a /etc/nix/nix.conf`

4. Install my environment:

    `nix profile install github:jeremyschlatter/nixpkgs`
    
5. Run my post-install script:

    `jeremy-post-install`
    
<sub>*I am using an [experimental feature](https://github.com/NixOS/rfcs/pull/49) called [Nix flakes](https://www.tweag.io/blog/2020-05-25-flakes). These steps are needed to opt into it before it stabilizes.</sub>

**Composing env definitions**

While the bulk of my environment is defined here in this repo, I also have a few pieces defined in private repos. This is useful for managing parts of my environment that either need to be secret or that I just don't want to publish for whatever reason.

I have not yet written instructions for how to compose these definitions. I may do that in the future.

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
