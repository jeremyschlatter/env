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
      customRC = builtins.readFile ./vim-config.vim;
      packages.mine = with pkgs.vimPlugins; {
        start = [
          ale
          ctrlp-vim
          vim-colors-solarized
          vim-fetch
          vim-go
          vim-nix
          vim-numbertoggle
          vim-unicoder
        ] ++ vim-plugins;
      };
     };
  });

  vim-fetch = (pkgs.vimUtils.buildVimPluginFrom2Nix {
    pname = "vim-fetch";
    version = "2019-04-03";
    src = pkgs.fetchFromGitHub {
      owner = "wsdjeg";
      repo = "vim-fetch";
      rev = "76c08586e15e42055c9c21321d9fca0677442ecc";
      sha256 = "0avcqjcqvxgj00r477ps54rjrwvmk5ygqm3qrzghbj9m1gpyp2kz";
    };
  });

  vim-numbertoggle = (pkgs.vimUtils.buildVimPluginFrom2Nix {
    pname = "numbertoggle";
    version = "2017-10-26";
    src = pkgs.fetchFromGitHub {
      owner = "jeffkreeftmeijer";
      repo = "vim-numbertoggle";
      rev = "cfaecb9e22b45373bb4940010ce63a89073f6d8b";
      sha256 = "1rrmvv7ali50rpbih1s0fj00a3hjspwinx2y6nhwac7bjsnqqdwi";
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
  docker
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
