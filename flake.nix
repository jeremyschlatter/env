{
  description = "Jeremy Schlatter's personal dev environment";

  inputs.stable.url = github:NixOS/nixpkgs/release-21.05;
  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixpkgs-unstable;

  outputs = { self, stable, nixpkgs }: {

    # Scripting!
    #
    # This is the most elaborate part of my nix config. Basically, this
    # converts my scripts/ directory into a bunch of nix packages, one per
    # script.
    #
    # It knows how to package a few different languages, and two different
    # styles of Go programs (with and without Go module dependencies).
    #
    # Scripts can declare in a comment at the top of the file that they depend
    # on other programs at runtime, and the packaging logic here will do the
    # appropriate bundling to ensure they have access to those programs.
    #
    # Python scripts can declare their pypi dependencies in a comment at the
    # top of file, too.
    #
    # All of this packaging works in sandbox mode, as well. This is important
    # to me because my work machine is in sandbox mode and I don't want to turn
    # that off.
    scripts = pkgs: scriptsPath:
      with builtins;
      let
        # custom build b/c the iterm2 package in nix is currently broken
        my-iterm2 = pypkgs: with pypkgs; buildPythonPackage rec {
          pname = "iterm2";
          version = "1.14";
          src = fetchPypi {
            inherit pname version;
            sha256 = "089pln3c41n6dyh91hw9gy6mpm9s663lpmdc4gamig3g6pfmbsk4";
          };
          doCheck = false;
          propagatedBuildInputs = [ protobuf websockets ];
        };
        builders = with pkgs;
          let
            wrapPath = name: deps:
              if deps == []
              then ""
              else ''
                . ${makeWrapper}/nix-support/setup-hook
                wrapProgram $out/bin/${name} --prefix PATH : ${
                  buildEnv {
                    name = "${name}-runtime-deps";
                    paths = deps;
                  }
                }/bin
                '';
            build = cmd: {deps}: file: name:
              runCommandLocal name { buildInputs = deps;} ''
                mkdir -p $out/bin
                file=${file}
                dest=$out/bin/${name}
                ${cmd}
                chmod +x $dest
                ${wrapPath name deps}
                '';
            interp = interpreter: build "echo '#!'${interpreter} | cat - $file > $dest";
          in {
            sh = interp "${bash}/bin/sh";
            go = build ''
              mkdir build
              cd build
              GOCACHE=$TMPDIR ${go}/bin/go mod init `basename $dest`
              GOCACHE=$TMPDIR GOPATH=$TMPDIR CGO_ENABLED=0 ${go}/bin/go build -o $dest $file
            '';
            goDir = src: name: deps: vendorSha256:
              buildGoModule {
                inherit name src vendorSha256;
                postInstall = "${wrapPath name deps}";
              };
            hs = build "${ghc}/bin/ghc -XLambdaCase -o $dest -outputdir $TMPDIR/$file $file";
            py = { deps, requirements ? [] }:
              interp ''/bin/sh ${
                python3.withPackages (
                  pkgs: map (x: getAttr x (pkgs // {iterm2 = my-iterm2 pkgs;})) requirements)
              }/bin/python'' { inherit deps; };
          };
        inherit (pkgs.lib) strings attrsets sources lists warn;
      in lists.forEach (attrNames (readDir scriptsPath)) (f:
        let fullPath = scriptsPath + "/${f}";
        in if sources.pathIsDirectory fullPath
           then
             if f == ".mypy_cache" then [] else
             let build = { deps = []; } // import (fullPath + "/build.nix") pkgs;
             in builders.goDir fullPath f build.deps build.sha256
           else
             let ext = elemAt (tail (split "\\." f)) 1;
                 name = strings.removeSuffix ".${ext}" f;
                 firstLine = head (split "\n" (strings.fileContents fullPath));
                 buildInfo = let x = strings.removeSuffix "#nix" firstLine; in
                   if x == firstLine then {} else fromJSON (elemAt (split "^[^ ]+" x) 2);
                 deps = map
                   (x: attrsets.getAttrFromPath (strings.splitString "." x) pkgs)
                   (buildInfo.deps or []);
             in if hasAttr ext builders
                then getAttr ext builders (buildInfo // { inherit deps; }) fullPath name
                else warn "not a recognized type of script: ${f}" []
        );

    # Simple builder: copy an entire directory into the nix store.
    copyDir = pkgs: name: from: to: pkgs.runCommand name {} "mkdir -p ${dirOf to} && cp -R ${from} ${to}";

    # This combines a list of flakes into a single package suitable for
    # installation into a profile. I use this function here in this flake.nix
    # file, but its most important purpose is to stitch multiple flakes
    # together.
    #
    # You can't see that in action, because those other flakes are private :(
    #
    # (In fact, the only reason I have this mechanism is so I can have private
    # flakes, so... 🤷)
    merge = flakes:
      let env = system:
        let pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
        in with pkgs.lib; pkgs.buildEnv {
          name = "bundled-environment";
          paths = trivial.pipe []
            (lists.forEach flakes
              (flake: super: lists.flatten (flake.packages {
                inherit system pkgs super;
                stable = import stable { inherit system; config.allowUnfree = true; };
              })));
        };
      in {
        x86_64-darwin = env "x86_64-darwin";
        x86_64-linux = env "x86_64-linux";
      };

    # This is what gets built if you build this flake directly, with no target specified.
    defaultPackage = self.merge [self];

    # My package collection.
    #
    # These are the software packages that I have installed on all of my machines.
    # They get installed _by being on this list_.
    #
    # Whenever I update this list, or any other part of this repo or any of my private nix repos,
    # I can re-run my "i" script (see scripts/i.py) on any of my machines to get the update.
    # Note that I am not limited to adding packages. I can delete or change anything here and
    # it will effectively delete or change the software on all of my machines.
    packages = { pkgs, stable, system, super }:
      let
        my-configs = self.copyDir pkgs "my-configs" ./config "$out/config";
        my-shell = pkgs.writeShellScriptBin "shell" ''exec ${pkgs.bashInteractive_5}/bin/bash --rcfile ${./config/bash/bashrc.sh} "$@"'';
        my-vim = import ./neovim.nix pkgs;
      in

      with pkgs; super ++ [
        my-configs # Config files for some of the programs in this list.
        (self.scripts pkgs ./scripts) # Little utility programs.

        # My terminal and shell. On macOS I use iTerm2 instead of kitty.
        kitty
        my-shell

        # Life on the command line.
        bat              # Display files, with syntax highlighting.
        bash-completion  # Tab-completion for a bunch of commands.
        cachix           # User-managed binary caches for nix.
        caddy            # Run a webserver.
        calc             # A simple calculator.
        cloc             # Count lines of code.
        (
          # prioritize the coreutils "link" command over the go "link" command.
          # (The latter is still available as "go tool link").
          hiPrio
            coreutils  # Basic file, shell and text manipulation utilities.
        )
        delta      # Better git diffs.
        direnv     # Set environment variables per-project.
        docker     # Bundle programs with their dependencies.
        exa        # List files in the current directory.
        fd         # Find file by name.
        fira-code  # Font that renders symbols in code nicely.
        fzf        # Fuzzy text search.
        git        # Track version history for text files.
        ghcid      # Fast typechecking feedback loop for Haskell development.
        gitAndTools.hub            # GitHub CLI.
        git-crypt         # Encrypt select files in a git repo.
        gnupg             # Cryptography tools.
        go                # Run Go code.
        google-cloud-sdk  # Google Cloud CLI.
        goimports         # Auto insert + remove import statements in Go files.
        (with haskellPackages; [
          (haskell.lib.justStaticExecutables hasktags)  # Jump-to-definition for Haskell.
        ])
        htop                  # Show CPU + memory usage.
        httpie                # Create and execute HTTP queries.
        jq                    # Zoom in on large JSON objects.
        less                  # Scroll through long files.
        lorri                 # Optimized direnv+nix integration.
        (python3.withPackages (pkgs: with pkgs; [
          ipython             # Better Python repl than the default.
          magic-wormhole      # Copy files between computers.
          pynvim
        ]))                   # Run Python.
        man-db                # View manuals. (Present on most OS's already -- this just ensures a recent version).
        mypy                  # Static type checking for python.
        my-vim                # Edit text.
        nix-index             # Find which nix package has the program you need.
        pm2                   # Nice interface for running long-lived background programs.
        ripgrep               # Text search. (Phenomenal grep replacement.)
        sd                    # Text find-and-replace. (Decent sed replacement.)
        stack                 # Build haskell projects.
        starship              # Nice command prompt.
        tldr                  # Show usage examples for common CLI programs.
        unzip                 # Open .zip files.
        watch                 # Run a command repeatedly.
        wget                  # Download files.
        (xonsh.overrideAttrs  # Bash+Python hybrid shell.
          (oldAttrs: {
            propagatedBuildInputs = with python3Packages; [ ply pygments ]; # drop prompt-toolkit
            doInstallCheck = false; # skip the tests, which fail if prompt-toolkit is disabled
          }))
      ] ++ lib.optionals (system == "x86_64-linux") [
        etcher # Burn .iso images to USB drives and SD cards, w/ user-friendly GUI.
        file   # Get high-level semantic info about a file.
      ];
  };
}
