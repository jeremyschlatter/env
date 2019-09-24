{ vim-plugins ? [] }:

let
  pkgs = import (fetchTarball {
    url = if builtins.currentSystem == "x86_64-darwin"
          then https://github.com/NixOS/nixpkgs-channels/tarball/nixpkgs-19.03-darwin
          else https://github.com/NixOS/nixpkgs/tarball/release-19.03;
  }) {};
  unstable = import (fetchTarball {
    url = https://github.com/NixOS/nixpkgs/tarball/release-19.09;
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

  my-go = pkgs.go_1_12;

  my-go-scripts = pkgs.runCommand "my-go-scripts" {
    buildInputs = [ my-go ];
  } ''
    mkdir -p $out/bin

    export GOCACHE=$TMPDIR/go-cache
    export GOPATH=$TMPDIR/go
    export CGO_ENABLED=0

    for file in ${./bin/go}/*
    do
      dest=$out/bin/$(basename -s .go $file)
      ${my-go}/bin/go build -o $dest $file
    done
  '';

  my-haskell-scripts = pkgs.runCommand "my-haskell-scripts" {
    buildInputs = [ pkgs.ghc ];
  } ''
    mkdir -p $out/bin

    for file in ${./bin/haskell}/*
    do
      base=$(basename -s .hs $file)
      dest=$out/bin/$base
      ${pkgs.ghc}/bin/ghc -XLambdaCase -o $dest -outputdir $TMPDIR/ghc-out-$base $file
    done
  '';

  my-python-scripts = pkgs.runCommand "my-python-scripts" {
    buildInputs = [ pkgs.python3 ];
  } ''
    mkdir -p $out/bin
    for file in ${./bin/python}/*
    do
      dest=$out/bin/$(basename -s .py $file)
      echo '#!'${pkgs.python3}/bin/python | cat - $file > $dest
      chmod +x $dest
    done
  '';

  my-rust-scripts = pkgs.runCommand "my-rust-scripts" {
    buildInputs = [ pkgs.rustc ];
  } ''
    mkdir -p $out/bin

    for file in ${./bin/rust}/*
    do
      dest=$out/bin/$(basename -s .rs $file)
      ${pkgs.rustc}/bin/rustc -o $dest $file
    done
  '';

  my-shell-scripts = pkgs.runCommand "my-shell-scripts" {
    buildInputs = [ pkgs.bash ];
  } ''
    mkdir -p $out/bin
    for file in ${./bin/sh}/*
    do
      dest=$out/bin/$(basename -s .sh $file)
      echo '#!'${pkgs.bash}/bin/sh | cat - $file > $dest
      chmod +x $dest
    done
  '';

  my-xdg-config = (pkgs.linkFarm "my-xdg-config" [ { name = "config"; path = "${./config}"; } ]);

  xdg = bin: pkg: pkgs.symlinkJoin {
    name = "my-" + bin;
    paths = [ pkg ];
    buildInputs = [ pkgs.makeWrapper my-xdg-config ];
    postBuild = "wrapProgram $out/bin/${bin} --set XDG_CONFIG_HOME ${my-xdg-config}/config";
  };

  my-vim = import ./neovim.nix pkgs vim-plugins;

in

with pkgs; [
  (xdg "bat" bat)
  caddy
  cachix
  cloc
  (
    # prioritize the coreutils "link" command over the go "link" command.
    # (The latter is still available as "go tool link").
    hiPrio coreutils
  )
  docker
  du-dust
  unstable.exa
  fd
  fzf
  (xdg "git" git)
  gitAndTools.hub
  git-crypt
  google-cloud-sdk
  goimports
  gotop
  (hiPrio haskellPackages.hasktags) # arbitrarily prioritize this ghc dylib over hoogle's
  haskellPackages.hoogle
  htop
  httpie
  ivy
  jq

#   click
#   kubectl
#   kubectx
#   kubetail

  my-go
  my-go-scripts
  my-haskell-scripts
  my-python-scripts
  my-rust-scripts
  my-shell-scripts
  my-vim
  my-xdg-config
  ngrok
  nodejs
  (python3.withPackages (pkgs: with pkgs; [
    ipython
    magic-wormhole
  ]))
  ripgrep
  stack
  tldr
  tree
  unzip
  watch
  wget
  xsv
  yarn

  # Experimental shells.
  fish
  zsh

] ++ maybe-nix

  # Linux-only packages
  ++ (stdenv.lib.lists.optionals stdenv.isLinux [
    gnome3.vte
    tilix
    tokei
  ])
