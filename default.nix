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
    url = https://github.com/NixOS/nixpkgs-channels/tarball/970b2b853d41ec80a3c2aba3e585f52818fbbfa3; # pinned from nixpkgs-unstable branch
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
  in unstable.python38.withPackages (pkgs: with pkgs; [
    ipython
    iterm2
    requests
    magic-wormhole
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
    postBuild = "wrapProgram $out/bin/${bin} --set ${envVar} ${my-xdg-config}/config/${relPath}";
  };
  xdg = withConfig "XDG_CONFIG_HOME" "";

  my-shell = pkgs.runCommand "my-shell" {} "mkdir -p $out/bin && ln -s ${pkgs.bashInteractive_5}/bin/bash $out/bin/shell";

  my-vim = import ./neovim.nix "${config/nvim/init.vim}" pkgs vim-plugins;

in

with pkgs; [
  my-xdg-config  # Config files for some of the programs in this list.
  my-scripts     # Little utility programs. Source in the bin/ directory.

  # My terminal and shell. On macOS I use iTerm2 instead of kitty.
  (withConfig "KITTY_CONFIG_DIRECTORY" "kitty" "kitty" kitty)
  my-shell

  # Life on the command line.
  (xdg "bat" bat)  # Display files, with syntax highlighting.
  bash-completion  # Tab-completion for a bunch of commands.
  bazelisk         # Build bazel projects.
  caddy            # Run a webserver.
  calc             # A simple calculator.
  cloc             # Count lines of code.
  comma            # Run programs without installing them.
  (
    # prioritize the coreutils "link" command over the go "link" command.
    # (The latter is still available as "go tool link").
    hiPrio
      coreutils  # Basic file, shell and text manipulation utilities.
  )
  direnv     # Set environment variables per-project.
  docker     # Bundle programs with their dependencies.
  entr       # Re-run builds when source files change. (I wrap this in "witch".)
  exa        # List files in the current directory.
  fd         # Find file by name.
  fira-code  # Font that renders symbols in code nicely.
  fzf        # Fuzzy text search.
  (xdg "git"
    git)     # Track version history for text files.
  ghc        # Compile Haskell code. (Usually I use stack instead).
  ghcid      # Evaluate Haskell code interactively.
  haskell.compiler.ghcjs86   # Compile Haskell code to javascript.
  gitAndTools.hub            # GitHub CLI.
  gitAndTools.diff-so-fancy  # Better text diffs for git.
  gnupg             # Cryptography tools.
  go                # Run Go code.
  google-cloud-sdk  # Google Cloud CLI.
  goimports         # Auto insert + remove import statements in Go files.
  gotop             # Show CPU + memory usage.
  (with haskellPackages; [
    (haskell.lib.justStaticExecutables hasktags)  # Jump-to-definition for Haskell.
    (haskell.lib.justStaticExecutables hoogle)    # Code search for Haskell.
  ])
  htop                  # Show CPU + memory usage.
  httpie                # Create and execute HTTP queries.
  jq                    # Zoom in on large JSON objects.
  my-python             # Run python.
  (xdg "vim" my-vim)    # Edit text.
  ngrok                 # Make public URLs for stuff on your laptop.
  nix-bash-completions  # Tab-complete for nix-env and friends.
  nodejs                # Run javascript.
  ripgrep               # Text search. (Phenomenal grep replacement.)
  unstable.stack        # Build haskell projects.
  unstable.starship     # Nice command prompt.
  tldr                  # Show usage examples for common CLI programs.
  tree                  # Show the files and folders in a directory tree.
  unzip                 # Open .zip files.
  watch                 # Run a command repeatedly.
  wget                  # Download files.
] ++ maybe-nix
