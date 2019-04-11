# My development environment

To use, first install [nix](https://nixos.org/nix/):

    $ curl https://nixos.org/nix/install | sh
    
Then use nix-env to install the rest:

    $ nix-env -if https://github.com/jeremyschlatter/nixpkgs/tarball/master

---

**Caveats**

- I like to use the `-r` flag with `nix-env -i`, but this configuration does not yet work well with that.
- I do not yet have a workflow for updating an installation of this environment, because nix will cache the github URL above.
- I do not yet have a workflow for making local modifications to this environment, including using local package channels.
- Not yet well tested. I'm only using this on one machine.
