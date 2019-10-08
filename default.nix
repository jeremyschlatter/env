{ patches ? [], vim-plugins ? [] }:

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

  my-scripts = name: cmd: pkgs.runCommand "my-${name}-scripts" {} ''
    mkdir -p $out/bin

    for file in ${./bin}/${name}/*
    do
      # Credit to https://stackoverflow.com/a/12152997 for the "%.*" syntax
      # for removing the file extension.
      dest=$out/bin/$(basename ''${file%.*})
      ${cmd}
      chmod +x $dest
    done
  '';

  my-go-scripts = my-scripts "go" ''
    GOCACHE=$TMPDIR/go-cache GOPATH=$TMPDIR/go CGO_ENABLED=0 \
    ${my-go}/bin/go build -o $dest $file
  '';

  my-haskell-scripts = my-scripts "haskell" ''
    ${pkgs.ghc}/bin/ghc -XLambdaCase -o $dest \
    -outputdir $TMPDIR/ghc-out-$(basename -s .hs $file) $file
  '';

  my-python-scripts = my-scripts "python" ''
    echo '#!'${pkgs.python3}/bin/python | cat - $file > $dest
  '';

  my-rust-scripts = my-scripts "rust" "${pkgs.rustc}/bin/rustc -o $dest $file";

  my-shell-scripts = my-scripts "sh" ''
    echo '#!'${pkgs.bash}/bin/sh | cat - $file > $dest
  '';

  my-xdg-config =
    let base = pkgs.runCommand "my-xdg-config" {} "mkdir $out && cp -R ${./config} $out/config";
    in if builtins.length patches == 0
       then base
       else unstable.applyPatches { src = base; patches = patches; };

  xdg = bin: pkg: pkgs.symlinkJoin {
    name = "my-" + bin;
    paths = [ pkg ];
    buildInputs = [ pkgs.makeWrapper my-xdg-config ];
    postBuild = "wrapProgram $out/bin/${bin} --set XDG_CONFIG_HOME ${my-xdg-config}/config";
  };

  my-shell = pkgs.runCommand "my-shell" {} "mkdir -p $out/bin && ln -s ${pkgs.bashInteractive_5}/bin/bash $out/bin/shell";

  my-vim = import ./neovim.nix pkgs vim-plugins;

in

with pkgs; [
  (xdg "bat" bat)
  caddy
  cloc
  (
    # prioritize the coreutils "link" command over the go "link" command.
    # (The latter is still available as "go tool link").
    hiPrio coreutils
  )
  docker
  unstable.exa
  fd
  fzf
  (xdg "git" git)
  gitAndTools.hub
  git-crypt
  gnupg
  google-cloud-sdk
  goimports
  gotop
  (hiPrio haskellPackages.hasktags) # arbitrarily prioritize this ghc dylib over idris's
  # haskellPackages.hoogle
  htop
  httpie
  (with idrisPackages; with-packages [
    contrib
  ])
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
  my-shell
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
