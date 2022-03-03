{
  description = "Jeremy Schlatter's personal dev environment";

  inputs.stable.url = github:NixOS/nixpkgs/release-21.11;
  inputs.nixpkgs.url = github:NixOS/nixpkgs/release-21.11;

  outputs = { self, stable, nixpkgs }: {

    # Function that automatically packages each of my one-off scripts.
    scripts = import ./scripts.nix;

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
              (flake: super: lists.flatten (flake.profile {
                inherit system pkgs super;
                stable = import stable { inherit system; config.allowUnfree = true; };
              })));
        };
      in {
        x86_64-darwin = env "x86_64-darwin";
        x86_64-linux = env "x86_64-linux";
      };

    # Experimental lite profile, for servers.
    packages.x86_64-darwin.lite = (self.merge [self.litePackages]).x86_64-darwin;
    packages.x86_64-linux.lite = (self.merge [self.litePackages]).x86_64-linux;
    litePackages.profile = { pkgs, ... }:
      with pkgs; [
        (self.copyDir pkgs "my-configs" ./config "$out/config")
        (import ./neovim.nix pkgs)
        exa
        git
        go
        ripgrep
        starship
      ];

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
    profile = { pkgs, stable, system, super }:
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
        coreutils  # Basic file, shell and text manipulation utilities.
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
        gotools           # Tools to facilitate coding in Go.
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
        ]))                   # Run Python.
        magic-wormhole        # Copy files between computers.
        man-db                # View manuals. (Present on most OS's already -- this just ensures a recent version).
        mypy                  # Static type checking for python.
        my-vim                # Edit text.
        nix-index             # Find which nix package has the program you need.
        pm2                   # Nice interface for running long-lived background programs.
        ripgrep               # Text search. (Phenomenal grep replacement.)
        sd                    # Text find-and-replace. (Decent sed replacement.)
        stack                 # Build haskell projects.
        starship              # Nice command prompt.
        unzip                 # Open .zip files.
        watch                 # Run a command repeatedly.
        wget                  # Download files.
        xonsh                 # Bash+Python hybrid shell.
      ] ++ lib.optionals (system == "x86_64-linux") [
        etcher # Burn .iso images to USB drives and SD cards, w/ user-friendly GUI.
        file   # Get high-level semantic info about a file.
      ];
  };
}
