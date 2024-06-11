{
  description = "Jeremy Schlatter's personal dev environment";

  inputs = {
    nixpkgs = { url = github:NixOS/nixpkgs/release-24.05; };
    nixpkgs-unstable = { url = github:NixOS/nixpkgs/nixpkgs-unstable; };
    crane = { url = github:ipetkov/crane; inputs.nixpkgs.follows = "nixpkgs"; };
    nixGL = { url = github:guibou/nixGL; inputs.nixpkgs.follows = "nixpkgs"; };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, crane, nixGL }: {

    # Function that automatically packages each of my one-off scripts.
    scripts = (import ./scripts.nix) crane;

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
    profile = { pkgs, system, super }:
      with pkgs;
      let
        unstable = import nixpkgs-unstable { inherit system; config.allowUnfree = true; };
        configs = self.copyDir pkgs "my-configs" ./config "$out/config";
        vim = neovim.override {
          viAlias = true;
          vimAlias = true;
          configure = {
            customRC = ''
              set runtimepath^=~/.config/nvim/
              source ~/.config/nvim/init.lua
            '';
            packages.mine = with vimPlugins; {
              start = [
                NeoSolarized
                camelcasemotion
                ctrlp-vim
                fzf-vim
                fzfWrapper
                leap-nvim
                rust-vim
                vim-better-whitespace
                vim-commentary
                vim-fetch
                vim-go
                vim-nix
                vim-numbertoggle
                vim-repeat
                vim-toml
                vim-unicoder
              ];
            };
           };
        };
        wrapBin = wrapper: pkg: symlinkJoin {
          pname = pkg.pname;
          name = pkg.pname;
          paths = [
            (writeShellScriptBin pkg.pname (builtins.replaceStrings ["_BIN_"] ["${pkg}/bin/${pkg.pname}"] wrapper))
            pkg
          ];
        };
        themed = light: dark: wrapBin ''
            [[ $(${coreutils}/bin/cat ~/.config/colors) = 'light' ]] && v='${light}' || v='${dark}'
            env "$v" _BIN_ $@
        '';
        bat-themed = themed "BAT_THEME=Solarized (light)" "BAT_THEME=Solarized (dark)";
        fixGL = wrapBin
          "${nixGL.packages."${system}".nixGLIntel}/bin/nixGLIntel _BIN_ $@";
        kitty = themed "KITTY_INITIAL_THEME=light" "KITTY_INITIAL_THEME=dark" (fixGL pkgs.kitty);
      in

      super ++ [
        configs # Config files for some of the programs in this list.
        (self.scripts pkgs ./scripts) # Little utility programs.

        # My shell.
        (writeShellScriptBin "shell" ''$HOME/.nix-profile/bin/fish "$@"'')
        (wrapBin ''_BIN_ -C "$HOME/.nix-profile/bin/_jeremy-shell-init fish | source"'' fish)
        (wrapBin ''ZDOTDIR=$HOME/.config/zsh _BIN_'' zsh)

        # Undollar: ignore leading $'s from copy-pasted commands.
        (writeShellScriptBin "$" "\"$@\"")

        # Life on the command line.
        (unstable.atuin.overrideAttrs (oldAttrs: {
          patches = oldAttrs.patches ++ [./atuin.patch];
        }))                   # Shell history search and sync.
        bash-completion       # Tab-completion for a bunch of commands.
        (bat-themed bat)      # Display files, with syntax highlighting.
        caddy                 # Run a webserver.
        calc                  # A simple arbitrary-precision calculator.
        comma                 # Use programs from the nix repo without installing them.
        coreutils             # Basic file, shell and text manipulation utilities.
        (bat-themed delta)    # Better git diffs.
        direnv                # Set environment variables per-project.
        docker                # Bundle programs with their dependencies.
        eza                   # List files in the current directory.
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
        inetutils             # Ping.
        jq                    # Zoom in on large JSON objects.
        kubectl               # Kubernetes CLI.
        less                  # Scroll through long files.
        magic-wormhole        # Copy files between computers.
        man-db                # View manuals. (Present on most OS's already -- this just ensures a recent version).
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
