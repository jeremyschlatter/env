let
  pkgs = import (fetchTarball {
    url = https://github.com/NixOS/nixpkgs/tarball/release-19.03;
  }) {};

  # This expression is designed to be installed with 'nix-env -ri', which deletes existing
  # packages. If the nix tools are in the profile now, we want them to stay in the profile
  # after 'nix-env -ri'.
  #
  # On NixOS, these tools are installed elsewhere. On other OS's, the default nix installation
  # puts them in the profile.
  maybe-nix = if builtins.pathExists ((builtins.getEnv "HOME") + "/.nix-profile/bin/nix-env")
              then [pkgs.nix]
              else [];
in

with pkgs; [
  bat
  cacert
  gitAndTools.hub
  go
  httpie
  python3
  ripgrep
  tldr
  tree
] ++ maybe-nix
