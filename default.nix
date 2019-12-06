{ patches ? [], vim-plugins ? [] }:

let
  pkgs = import (fetchTarball {
    url = if builtins.currentSystem == "x86_64-darwin"
          then https://github.com/NixOS/nixpkgs-channels/tarball/nixpkgs-19.09-darwin
          # else https://github.com/NixOS/nixpkgs-channels/tarball/nixos-19.09;
          else https://github.com/NixOS/nixpkgs-channels/tarball/688f9ef18413480b0575299bd748f9179ff6844b;
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

  # I have some utility scripts in different languages in the bin/ directory of this repo.
  # This expression compiles and installs them.
  my-scripts = let
    build-with-inputs = inputs: name: cmd:
      pkgs.runCommand "my-${name}-scripts" {buildInputs = inputs;} ''
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
    build = build-with-inputs [];
    interp = name: interpreter: build name "echo '#!'${interpreter} | cat - $file > $dest";
  in [
    (build "go" "GOCACHE=$TMPDIR GOPATH=$TMPDIR CGO_ENABLED=0 ${pkgs.go}/bin/go build -o $dest $file")
    (build "haskell" "${pkgs.ghc}/bin/ghc -XLambdaCase -o $dest -outputdir $TMPDIR/$file $file")
    (interp "python" "${pkgs.python3}/bin/python")
    (interp "sh" "${pkgs.bash}/bin/sh")
    (build-with-inputs [pkgs.gcc] "rust" "${pkgs.rustc}/bin/rustc -o $dest $file")
  ];

  my-xdg-config =
    let base = pkgs.runCommand "my-xdg-config" {} "mkdir $out && cp -R ${./config} $out/config";
    in if builtins.length patches == 0
       then base
       else pkgs.applyPatches { src = base; patches = patches; };

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
  bash-completion
  caddy
  calc
  cloc
  (
    # prioritize the coreutils "link" command over the go "link" command.
    # (The latter is still available as "go tool link").
    hiPrio coreutils
  )
  docker
  exa
  fd
  fira-code
  fzf
  (xdg "git" git)
  ghc # just for ghcid
  ghcid
  gitAndTools.hub
  gitAndTools.diff-so-fancy
  git-crypt
  gnupg
  go
  google-cloud-sdk
  goimports
  gotop
  (with haskellPackages; [
    (hiPrio hasktags) # arbitrarily prioritize this ghc dylib over idris's
    hoogle
  ])
  htop
  httpie
  (with idrisPackages; with-packages [
    contrib
  ])
  jq
  (xdg "kitty" kitty)
  my-scripts
  (xdg "vim" my-vim)
  my-xdg-config
  my-shell
  ngrok
  nix-bash-completions
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

] ++ maybe-nix
