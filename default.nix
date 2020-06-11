{ patches ? [], vim-plugins ? [] }:

let
  pkgs = import (fetchTarball {
    url = if builtins.currentSystem == "x86_64-darwin"
          then https://github.com/NixOS/nixpkgs-channels/tarball/b119c0939780ac70f4005cb146606f471c0692a8 # pinned from nixpkgs-20.03-darwin branch
          else https://github.com/NixOS/nixpkgs-channels/tarball/nixpkgs-20.03;
  }) {
    config = {
      allowUnfree = true; # required for ngrok
    };
  };

  unstable = import (fetchTarball {
    url = https://github.com/NixOS/nixpkgs-channels/tarball/nixpkgs-unstable;
  }) {};

  comma = (import (pkgs.fetchFromGitHub {
    owner = "Shopify";
    repo = "comma";
    rev = "4a62ec1";
    sha256 = "0n5a3rnv9qnnsrl76kpi6dmaxmwj1mpdd2g0b4n1wfimqfaz6gi1";
  }) {pkgs = pkgs;});

  # This expression is designed to be installed with 'nix-env -ri', which deletes existing
  # packages. If the nix tools are in the profile now, we want them to stay in the profile
  # after 'nix-env -ri'.
  #
  # On NixOS, these tools are installed elsewhere. On other OS's, the default nix installation
  # puts them in the profile.
  maybe-nix = if builtins.pathExists ((builtins.getEnv "HOME") + "/.nix-profile/bin/nix-env")
              then with pkgs; [nix cacert]
              else [];

  my-python = let
    # custom build b/c the iterm2 package is not bundled into nix
    my-iterm2 = with pkgs.python3.pkgs; buildPythonPackage rec {
      pname = "iterm2";
      version = "1.14";
      src = fetchPypi {
        inherit pname version;
        sha256 = "089pln3c41n6dyh91hw9gy6mpm9s663lpmdc4gamig3g6pfmbsk4";
      };
      doCheck = false;
      propagatedBuildInputs = [ protobuf websockets ];
    };
  in pkgs.python3.withPackages (pkgs: with pkgs; [
    ipython
    requests
    # magic-wormhole
    my-iterm2
  ]);

  # I have some utility scripts in different languages in the bin/ directory of this repo.
  # This expression compiles and installs them.
  my-scripts = let
    build-with-inputs = inputs: name: cmd:
      pkgs.runCommand "my-${name}-scripts" {buildInputs = inputs;} ''
        mkdir -p $out/bin

        # Go-specific initialization. Runs for all languages, but happens
        # not to cause problems for any of the non-Go ones.
        mkdir build
        cd build
        GOCACHE=$TMPDIR ${pkgs.go}/bin/go mod init apps

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
    (build "go" "cp $file . && GOCACHE=$TMPDIR GOPATH=$TMPDIR CGO_ENABLED=0 ${pkgs.go}/bin/go build -o $dest $(basename $file)")
    (build "haskell" "${pkgs.ghc}/bin/ghc -XLambdaCase -o $dest -outputdir $TMPDIR/$file $file")
    (interp "python" "/bin/sh ${my-python}/bin/python")
    (interp "sh" "${pkgs.bash}/bin/sh")
    (build-with-inputs [pkgs.gcc] "rust" "${pkgs.rustc}/bin/rustc -o $dest $file")
  ];

  my-xdg-config =
    let base = pkgs.runCommand "my-xdg-config" {} "mkdir $out && cp -R ${./config} $out/config";
    in if builtins.length patches == 0
       then base
       else pkgs.applyPatches { src = base; patches = patches; };

  withConfig = envVar: relPath: bin: pkg: pkgs.symlinkJoin {
    name = "my-" + bin;
    paths = [ pkg ];
    buildInputs = [ pkgs.makeWrapper my-xdg-config ];
    postBuild = "wrapProgram $out/bin/${bin} --set ${envVar} ${my-xdg-config}/${relPath}";
  };
  xdg = withConfig "XDG_CONFIG_HOME" "config";

  my-shell = pkgs.runCommand "my-shell" {} "mkdir -p $out/bin && ln -s ${pkgs.bashInteractive_5}/bin/bash $out/bin/shell";

  my-vim = import ./neovim.nix "${config/nvim/init.vim}" pkgs vim-plugins;

in

with pkgs; [
  (xdg "bat" bat)
  bash-completion
  bazelisk
  caddy
  calc
  cloc
  comma
  (
    # prioritize the coreutils "link" command over the go "link" command.
    # (The latter is still available as "go tool link").
    hiPrio coreutils
  )
  direnv
  docker
  entr
  exa
  fd
  fira-code
  fzf
  (xdg "git" git)
  ghc # just for ghcid
  ghcid
  haskell.compiler.ghcjs86
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
  jq
  (withConfig "KITTY_CONFIG_DIRECTORY" "config/kitty" "kitty" kitty)
  my-python
  my-scripts
  (xdg "vim" my-vim)
  my-xdg-config
  my-shell
  ngrok
  niv
  nix-bash-completions
  nodejs
  ripgrep
  unstable.stack
  tldr
  tree
  unzip
  watch
  wget
  xsv
  yarn
] ++ maybe-nix
