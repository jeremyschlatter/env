{
  description = "Jeremy Schlatter's personal dev environment";

  inputs = {
    unstable = { url = github:NixOS/nixpkgs/nixpkgs-unstable; };
    nixpkgs = { url = github:NixOS/nixpkgs/release-22.05; };
    naersk = { url = github:nix-community/naersk; inputs.nixpkgs.follows = "nixpkgs"; };
    nixGL = { url = github:guibou/nixGL; inputs.nixpkgs.follows = "nixpkgs"; };
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
        let pkgs = import nixpkgs { inherit system; config.allowUnfree = true; overlays = [ (final: prev: { golangci-lint = prev.golangci-lint.overrideAttrs (_: { meta.broken = false; } ); } ) ]; };
        in with pkgs.lib; pkgs.buildEnv {
          name = "bundled-environment";
          paths = trivial.pipe []
            (lists.forEach flakes
              (flake: super: lists.flatten (flake.profile {
                inherit system pkgs super;
                unstable = import unstable { inherit system; config.allowUnfree = true; config.permittedInsecurePackages = ["electron-12.2.3"]; };
                x86 = import nixpkgs { system = "x86_64-${builtins.elemAt (strings.splitString "-" system) 1 }"; config.allowUnfree = true; };
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
    profile = { pkgs, unstable, system, super, x86 }:
      with pkgs;
      let
        configs = self.copyDir pkgs "my-configs" ./config "$out/config";
        shell = writeShellScriptBin "shell" ''exec ${bashInteractive_5}/bin/bash --rcfile ${./config/bash/bashrc.sh} "$@"'';
        vim = import ./neovim.nix pkgs;
        themed = light: dark: pkg: writeShellScriptBin pkg.pname ''
          [[ $(${coreutils}/bin/cat ~/.config/colors) = 'light' ]] && v='${light}' || v='${dark}'
          env "$v" ${pkg}/bin/${pkg.pname} $@
        '';
        bat-themed = themed "BAT_THEME=Solarized (light)" "BAT_THEME=Solarized (dark)";
        fixGL = pkg: [pkg (hiPrio (writeShellScriptBin pkg.pname ''
          ${nixGL.packages."${system}".nixGLIntel}/bin/nixGLIntel ${pkg}/bin/${pkg.pname} $@
        ''))];
        mcfly = themed "MCFLY_LIGHT=1" "=" pkgs.mcfly;
      in

      super ++ [
        configs # Config files for some of the programs in this list.
        (self.scripts system pkgs ./scripts) # Little utility programs.

        # My shell.
        shell

        # Undollar: ignore leading $'s from copy-pasted commands.
        (writeShellScriptBin "$" "\"$@\"")

        # Life on the command line.
        bash-completion       # Tab-completion for a bunch of commands.
        (bat-themed bat)      # Display files, with syntax highlighting.
        caddy                 # Run a webserver.
        comma                 # Use programs from the nix repo without installing them.
        coreutils             # Basic file, shell and text manipulation utilities.
        (bat-themed delta)    # Better git diffs.
        direnv                # Set environment variables per-project.
        docker                # Bundle programs with their dependencies.
        exa                   # List files in the current directory.
        fd                    # Find file by name.
        fira-code             # Font that renders symbols in code nicely.
        git                   # Track version history for text files.
        gitAndTools.hub       # GitHub CLI.
        gnumake               # Near-omnipresent generic build tool.
        go_1_18               # Run Go code.
        google-cloud-sdk      # Google Cloud CLI.
        gotools               # Tools to facilitate coding in Go.
        htop                  # Show CPU + memory usage.
        x86.httpie            # Create and execute HTTP queries.
        jq                    # Zoom in on large JSON objects.
        less                  # Scroll through long files.
        x86.magic-wormhole    # Copy files between computers.
        man-db                # View manuals. (Present on most OS's already -- this just ensures a recent version).
        mcfly                 # Shell history search.
        nix-direnv            # Optimized direnv+nix integration.
        nix-index             # Find which nix package has the program you need.
        (python3.withPackages # Run Python.
          (ps: [ps.ipython])) # Better Python repl than the default.
        ripgrep               # Text search. (Phenomenal grep replacement.)
        starship              # Nice command prompt.
        unzip                 # Open .zip files.
        vim                   # Edit text.
        watch                 # Run a command repeatedly.
        wget                  # Download files.
        zoxide                # A smarter cd command.
      ] ++ lib.optionals (system == "x86_64-linux") [
        # etcher                # Burn .iso images to USB drives and SD cards, w/ user-friendly GUI.
        file                  # Get high-level semantic info about a file.
        (fixGL kitty)         # My terminal. On macOS I use iTerm2 instead of kitty.
        nix                   # Nix.
      ];
  };
}
