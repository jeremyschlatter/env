# My development environment

To use, first install [nix](https://nixos.org/nix/):

    $ curl https://nixos.org/nix/install | sh

Then use nix-env to install the rest:

    $ nix-env -if https://github.com/jeremyschlatter/nixpkgs/tarball/master?$(date +%s)

(the query string at the end prevents caching)

---

**Caveats**

- I like to use the `-r` flag with `nix-env -i`, but this configuration does not yet work well with that.
- I do not yet have a workflow for making local modifications to this environment, including using local package channels.
- Not yet well tested. I'm only using this on one machine.
