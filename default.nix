{ vim-plugins ? [] }:

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
              then with pkgs; [nix cacert]
              else [];

  ivy = (pkgs.buildGoPackage {
    name = "ivy";
    goPackagePath = "robpike.io/ivy";
    # TODO: Would be nice to retrieve this from robpike.io instead.
    src = pkgs.fetchFromGitHub {
        owner = "robpike";
        repo = "ivy";
        rev = "master";
        sha256 = "05spzinlkdngnwgmp0bhp72h1s2dzbrxhyvjscy3r2hm0vdlkhz2";
      };
  });

  my-xdg-config = (pkgs.linkFarm "my-xdg-config" [ { name = "config"; path = "${./config}"; } ]);

  my-vim = import ./neovim.nix pkgs vim-plugins;

in

with pkgs; [
  bat
  caddy
  click
  cloc
  docker
  du-dust
  exa
  fd
  git
  gitAndTools.hub
  google-cloud-sdk
  go
  goimports
  htop
  httpie
  ivy
  jq
  kubectl
  kubectx
  kubetail
  my-vim
  my-xdg-config
  (python3.withPackages (pkgs: with pkgs; [
    ipython
    magic-wormhole
  ]))
  ngrok
  ripgrep
  tldr
  tree
  unzip
  watch
  wget
  xsv
] ++ maybe-nix
