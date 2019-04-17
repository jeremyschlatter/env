{ vim-plugins ? [] }:

let
  pkgs = import (fetchTarball {
    url = https://github.com/NixOS/nixpkgs/tarball/release-19.03;
  }) {};
  unstable = import (fetchTarball {
    url = https://github.com/NixOS/nixpkgs-channels/tarball/nixos-unstable;
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

  my-vim = (pkgs.neovim.override {
    viAlias = true;
    vimAlias = true;
    configure = {
      customRC = ''
        set background=light
      '';
      packages.mine = with pkgs.vimPlugins; {
        start = [
          vim-go
          vim-nix
          vim-unicoder
        ] ++ vim-plugins;
      };
     };
  });

  vim-unicoder = (pkgs.vimUtils.buildVimPluginFrom2Nix {
    pname = "unicoder.vim";
    version = "2019-04-01";
    src = pkgs.fetchFromGitHub {
      owner = "arthurxavierx";
      repo = "vim-unicoder";
      rev = "b360487430fac5e369433a597733588748eff663";
      sha256 = "1yvgcyaqcb2c2vdr70kg335s3bwyd9kz6liiqvfhyagf24s4pcgs";
    };
  });

in

with pkgs; [
  bat
  caddy
  click
  cloc
  du-dust
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
