{
  description = "Jeremy Schlatter's personal dev environment";

  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixpkgs-20.03-darwin;
  inputs.nixpkgs-unstable.url = github:NixOS/nixpkgs/nixpkgs-unstable;

  outputs = { self, nixpkgs, nixpkgs-unstable }: {
    my-scripts = pkgs: binPath:
      with pkgs; let
        build-with-inputs = inputs: name: cmd:
          runCommand "my-${name}-scripts" {buildInputs = inputs;} ''
            mkdir -p $out/bin

            # Go-specific initialization.
            mkdir build
            cd build
            GOCACHE=$TMPDIR ${go}/bin/go mod init apps

            for file in ${binPath}/${name}/*
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
        (build "go" "cp $file . && GOCACHE=$TMPDIR GOPATH=$TMPDIR CGO_ENABLED=0 ${go}/bin/go build -o $dest $(basename $file)")
        (build "haskell" "${ghc}/bin/ghc -XLambdaCase -o $dest -outputdir $TMPDIR/$file $file")
        (interp "python" "/bin/sh ${python38.withPackages (pkgs: with pkgs; [requests])}/bin/python")
        (interp "sh" "${bash}/bin/sh")
        (build-with-inputs [gcc] "rust" "${rustc}/bin/rustc -o $dest $file")
      ];
    my-configs = pkgs: pkgs.runCommand "my-configs" {} "mkdir $out && cp -R ${./config} $out/config";
    pkgs = system: {
      inherit system;
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true; # required for ngrok
        };
      };
      unstable = import nixpkgs-unstable { inherit system; };
    };
    bundle = name: cb: system:
      let
        x = (self.pkgs system);
      in with x.pkgs;
        x.pkgs.buildEnv {
          inherit name;
          paths = x.pkgs.lib.lists.flatten (cb x);
        };

    defaultPackage.x86_64-darwin = self.bundle "jeremys-env" self.packages "x86_64-darwin";
    defaultPackage.x86_64-linux  = self.bundle "jeremys-env" self.packages "x86_64-linux";

    packages = { pkgs, unstable, system }:
      let
        my-shell = pkgs.linkFarm "my-shell" [{name="bin/shell"; path="${pkgs.bashInteractive_5}/bin/bash";}];
        my-vim = import ./neovim.nix pkgs;
      in

      with pkgs; [
        (self.my-configs pkgs) # Config files for some of the programs in this list.
        (self.my-scripts pkgs ./bin) # Little utility programs. Source in the bin/ directory.

        # My terminal and shell. On macOS I use iTerm2 instead of kitty.
        kitty
        my-shell

        # Reinstall nix itself.
        unstable.nixFlakes
        unstable.cacert

        # Life on the command line.
        bat              # Display files, with syntax highlighting.
        bash-completion  # Tab-completion for a bunch of commands.
        bazelisk         # Build bazel projects.
        caddy            # Run a webserver.
        calc             # A simple calculator.
        cloc             # Count lines of code.
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
        unstable.fira-code  # Font that renders symbols in code nicely.
        fzf        # Fuzzy text search.
        git        # Track version history for text files.
        ghc        # Compile Haskell code. (Usually I use stack instead).
        ghcid      # Evaluate Haskell code interactively.
        haskell.compiler.ghcjs86   # Compile Haskell code to javascript.
        gitAndTools.hub            # GitHub CLI.
        gitAndTools.diff-so-fancy  # Better text diffs for git.
          # Needed by diff-so-fancy, but not bundled with it :/
          less
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
        (unstable.python38.withPackages (pkgs: with pkgs; [
          ipython             # Better Python repl than the default.
          magic-wormhole      # Copy files between computers.
        ]))                   # Run Python.
        my-vim                # Edit text.
        ngrok                 # Make public URLs for stuff on your laptop.
        nix-bash-completions  # Tab-complete for nix-env and friends.
        nix-index             # Find which nix package has the program you need.
        nodejs                # Run javascript.
        ripgrep               # Text search. (Phenomenal grep replacement.)
        stack                 # Build haskell projects.
        unstable.starship     # Nice command prompt.
        tldr                  # Show usage examples for common CLI programs.
        tree                  # Show the files and folders in a directory tree.
        unzip                 # Open .zip files.
        watch                 # Run a command repeatedly.
        wget                  # Download files.
      ] ++ (if system != "x86_64-linux" then [] else [
        file
      ]);
  };
}
