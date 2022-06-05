{
  description = "Jeremy Schlatter's personal dev environment";

  inputs = {
    unstable.url = github:NixOS/nixpkgs/nixpkgs-unstable;
    nixpkgs.url = github:NixOS/nixpkgs/release-22.05;
    naersk.url = github:nix-community/naersk;
    nixGL.url = github:guibou/nixGL;
    nixGL.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, unstable, nixpkgs, naersk, nixGL }: {

    # Function that automatically packages each of my one-off scripts.
    scripts = system: (import ./scripts.nix) naersk.lib."${system}";

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
                unstable = import unstable { inherit system; config.allowUnfree = true; config.permittedInsecurePackages = ["electron-12.2.3"]; };
              })));
        };
      in {
        aarch64-darwin = env "aarch64-darwin";
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
    profile = { pkgs, unstable, system, super }:
      let
        my-configs = self.copyDir pkgs "my-configs" ./config "$out/config";
        my-shell = pkgs.writeShellScriptBin "shell" ''exec ${pkgs.bashInteractive_5}/bin/bash --rcfile ${./config/bash/bashrc.sh} "$@"'';
        my-vim = import ./neovim.nix pkgs unstable;
        themed = pkg: pkgs.writeShellScriptBin pkg.pname ''
          BAT_THEME="Solarized (`${pkgs.coreutils}/bin/cat ~/.config/colors`)" ${pkg}/bin/${pkg.pname} $@
        '';
        fixGL = pkg: [pkg (pkgs.hiPrio (pkgs.writeShellScriptBin pkg.pname ''
          ${nixGL.packages."${system}".nixGLIntel}/bin/nixGLIntel ${pkg}/bin/${pkg.pname} $@
        ''))];
      in

      with pkgs; super ++ [
        my-configs # Config files for some of the programs in this list.
        (self.scripts system pkgs ./scripts) # Little utility programs.
        # nix

        # My shell.
        my-shell

        # Undollar: ignore leading $'s from copy-pasted commands.
        (writeShellScriptBin "$" "\"$@\"")

        # Life on the command line.
        (themed bat)     # Display files, with syntax highlighting.
        bash-completion  # Tab-completion for a bunch of commands.
        caddy            # Run a webserver.
        calc             # A simple calculator.
        cloc             # Count lines of code.
        comma            # Use programs from the nix repo without installing them.
        coreutils        # Basic file, shell and text manipulation utilities.
        (themed delta)   # Better git diffs.
        direnv     # Set environment variables per-project.
        docker     # Bundle programs with their dependencies.
        exa        # List files in the current directory.
        fd         # Find file by name.
        fira-code  # Font that renders symbols in code nicely.
        fzf        # Fuzzy text search.
        git        # Track version history for text files.
        gitAndTools.hub   # GitHub CLI.
        git-crypt         # Encrypt select files in a git repo.
        gnumake           # Near-omnipresent generic build tool.
        gnupg             # Cryptography tools.
        go_1_18           # Run Go code.
        google-cloud-sdk  # Google Cloud CLI.
        gotools           # Tools to facilitate coding in Go.
        htop                  # Show CPU + memory usage.
        unstable.httpie       # Create and execute HTTP queries.
        jq                    # Zoom in on large JSON objects.
        less                  # Scroll through long files.
        (python3.withPackages (pkgs: with pkgs; [
          ipython             # Better Python repl than the default.
        ]))                   # Run Python.
        unstable.magic-wormhole        # Copy files between computers.
        man-db                # View manuals. (Present on most OS's already -- this just ensures a recent version).
        mypy                  # Static type checking for python.
        my-vim                # Edit text.
        nix-direnv            # Optimized direnv+nix integration.
        nix-index             # Find which nix package has the program you need.
        pm2                   # Nice interface for running long-lived background programs.
        ripgrep               # Text search. (Phenomenal grep replacement.)
        sd                    # Text find-and-replace. (Decent sed replacement.)
        starship              # Nice command prompt.
        unzip                 # Open .zip files.
        watch                 # Run a command repeatedly.
        wget                  # Download files.
        zoxide
      ] ++ lib.optionals (system == "x86_64-linux") [
        # My terminal. On macOS I use iTerm2 instead of kitty.
        (fixGL kitty)
        file   # Get high-level semantic info about a file.
        # etcher # Burn .iso images to USB drives and SD cards, w/ user-friendly GUI.
      ];
  };
}
