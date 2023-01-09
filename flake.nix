{
  description = "Jeremy Schlatter's personal dev environment";

  inputs = {
    unstable = { url = github:NixOS/nixpkgs/nixpkgs-unstable; };
    nixpkgs = { url = github:NixOS/nixpkgs/release-22.11; };
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
        let pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
        in with pkgs.lib; pkgs.buildEnv {
          name = "bundled-environment";
          paths = trivial.pipe []
            (lists.forEach flakes
              (flake: super: lists.flatten (flake.profile {
                inherit system pkgs super;
                unstable = import unstable { inherit system; config.allowUnfree = true; };
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

#     clipboard = { gccStdenv /* latest clang does not yet support std::jthread */, fetchFromGitHub, cmake }:
#       let version = "main"; in
#       gccStdenv.mkDerivation {
#         pname = "clipboard";
#         inherit version;
#         src = fetchFromGitHub {
#           owner = "Slackadays";
#           repo = "Clipboard";
#           rev = version;
#           sha256 = "sha256-SnfUeFOcwUrAi3MAdQE2EhhlygEIcnHC2RrWIdl10Fc=";
#         };
#         nativeBuildInputs = [ cmake ];
#         installPhase = ''
#           mkdir -p $out/bin
#           mv clipboard $out/bin
#           ln -s clipboard $out/bin/cb
#         '';
#       };

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
        wrapBinWithinPkg = wrapper: pkg: symlinkJoin {
          pname = pkg.pname;
          name = pkg.pname;
          paths = [
            (writeShellScriptBin pkg.pname (builtins.replaceStrings ["_BIN_"] ["${pkg}/bin/${pkg.pname}"] wrapper))
            pkg
          ];
        };
        themed = light: dark: wrapBinWithinPkg ''
            [[ $(${coreutils}/bin/cat ~/.config/colors) = 'light' ]] && v='${light}' || v='${dark}'
            env "$v" _BIN_ $@
        '';
        bat-themed = themed "BAT_THEME=Solarized (light)" "BAT_THEME=Solarized (dark)";
        fixGL = wrapBinWithinPkg
          "${nixGL.packages."${system}".nixGLIntel}/bin/nixGLIntel _BIN_ $@";
        mcfly = themed "MCFLY_LIGHT=1" "=" pkgs.mcfly;
        kitty = themed "KITTY_INITIAL_THEME=light" "KITTY_INITIAL_THEME=dark" (fixGL pkgs.kitty);
      in

      super ++ [
        configs # Config files for some of the programs in this list.
        (self.scripts system pkgs ./scripts) # Little utility programs.

        # My shell.
        shell
        fish
        zsh

        # Undollar: ignore leading $'s from copy-pasted commands.
        (writeShellScriptBin "$" "\"$@\"")

        # (pkgs.callPackage self.clipboard {})

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
        gnumake               # Near-omnipresent generic build tool.
        gnupg                 # gpg, I use it to sign git commits
        go                    # Run Go code.
        google-cloud-sdk      # Google Cloud CLI.
        gotools               # Tools to facilitate coding in Go.
        htop                  # Show CPU + memory usage.
        httpie                # Create and execute HTTP queries.
        hub                   # GitHub CLI.
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
        kitty                 # My terminal. On macOS I use iTerm2 instead of kitty.
      ];
  };
}
