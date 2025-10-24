# My development environment

**Overview**

I use the [nix](https://nixos.org/) package manager on all of my (non-mobile) computers, and it is very helpful.

There are many ways that this setup provides me value, but one of the most legible is this: I have a fairly customized environment (including a few dozen [tools](https://github.com/jeremyschlatter/nixpkgs/blob/c97e18297883df763df2326bcf8231d9bcd58f11/flake.nix#L164-L217), a couple hundred lines of [config](config), and about a dozen custom [scripts](scripts)) that **I am able to install and synchronize across multiple machines**, including my personal MacBook Pro, my Linux work machine, and a few servers I use for hobby projects.

**Usage**

1. [Install nix](https://github.com/DeterminateSystems/nix-installer?tab=readme-ov-file#the-determinate-nix-installer)

2. Install my environment:

    `nix profile add github:jeremyschlatter/nixpkgs`
    
3. Run my post-install script:

    `jeremy-post-install`

**Composing env definitions**

While the bulk of my environment is defined here in this repo, I also have a few pieces defined in private repos. This is useful for managing parts of my environment that either need to be secret or that I just don't want to publish for whatever reason.

I have not yet written instructions for how to compose these definitions. I may do that in the future.

**About my environment**

This config installs [ghostty](https://ghostty.org/), which I use as my terminal emulator.

**Other Notes**

To pick up application launchers in Gnome I made this symlink:

    rmdir ~/.local/share/applications
    ln -s ~/.nix-profile/share/applications/ ~/.local/share/

To get desktop icons:

    ln -s ~/.nix-profile/share/icons/ ~/.local/share/
