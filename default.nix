let
  pkgs = import (fetchTarball {
    url = https://github.com/NixOS/nixpkgs/tarball/19.03;
  }) {};
in

with pkgs; [
  bat
  ripgrep
  tldr
  httpie
  tree
  nix
]
