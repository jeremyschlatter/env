{
  description = "Jeremy Schlatter's personal dev environment";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixpkgs-unstable;
    crane.url = github:ipetkov/crane;
    personal = {
      url = github:jeremyschlatter/packages;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    starship-jj = {
      url = gitlab:lanastara_foss/starship-jj;
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, crane, personal, starship-jj }: {

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
        let pkgs = import nixpkgs { inherit system; config.allowUnfree = true; overlays = [ self.overlays.default ]; };
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
        aarch64-linux = env "aarch64-linux";
        x86_64-linux = env "x86_64-linux";
      };

    overlays.default = final: prev: {
      # Workaround for https://github.com/neovim/neovim/issues/29550
      # Remove when 0.12.0 is released.
      neovim-unwrapped = prev.neovim-unwrapped.overrideAttrs (prevAttrs: rec {
        version = "0.12.0-dev";
        src = prevAttrs.src.override {
          rev = "9139c4f90ff8dc7819474a3bd8d65ec7565c764d";
          tag = null;
          hash = "sha256-59nW1b1EQaFliNVWT7jp82Crn7jp/CgRNNlm+0bwa9c=";
        };
      });
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
        configs = self.copyDir pkgs "my-configs" ./config "$out/config" // { pname = "my-configs"; version = "1"; };
        my-bash = writeShellScriptBin "bash" ''exec ${bashInteractive}/bin/bash --rcfile ${./config/bash/bashrc.sh} "$@"''
          // { version = bashInteractive.version; pname = "bash"; };
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
                camelcasemotion
                ctrlp-vim
                fzf-vim
                fzfWrapper
                leap-nvim
                nvim-config-local
                (nvim-treesitter.withPlugins (p:
                  # Workaround for bugs in tree-sitter-dockerfile. Remove if fixed:
                  # https://github.com/camdencheek/tree-sitter-dockerfile/issues/51
                  # https://github.com/camdencheek/tree-sitter-dockerfile/issues/65
                  builtins.filter (x: x != p.dockerfile) nvim-treesitter.allGrammars
                ))
                catppuccin-nvim
                nvim-ts-context-commentstring
                guess-indent-nvim
                (vimUtils.buildVimPlugin {
                  pname = "tabs-vs-spaces.nvim";
                  version = "2024-05-30";
                  src = fetchFromGitHub {
                    owner = "tenxsoydev";
                    repo = "tabs-vs-spaces.nvim";
                    rev = "86cfc69bee95647b802ea49fcb816ff0ea798fc7";
                    sha256 = "sha256-a3q4MfSrewog3PHe9ubW6ehFWjuHnpaHTDMkMJLvTds=";
                  };
                  meta.homepage = "https://github.com/tenxsoydev/tabs-vs-spaces.nvim/";
                })
                vim-better-whitespace
                vim-commentary
                vim-fetch
                vim-go
                vim-numbertoggle
                vim-repeat
                vim-unicoder
              ];
            };
           };
        };
        wrapBin = wrapper: pkg: symlinkJoin {
          pname = pkg.pname;
          name = pkg.pname;
          version = pkg.version;
          paths = [
            (writeShellScriptBin pkg.pname (builtins.replaceStrings ["_BIN_"] ["${pkg}/bin/${pkg.pname}"] wrapper))
            pkg
          ];
        };
        themed = var: light: dark: wrapBin ''
            [[ $(_colorscheme read) = 'light' ]] && c='${light}' || c='${dark}'
            env "${var}=$c" _BIN_ "$@"
        '';
        mypkgs = personal.packages.${system};
        patch = pkg: patches: pkg.overrideAttrs (oldAttrs: {
          patches = (oldAttrs.patches or []) ++ patches;
        });
      in

      super
      ++ (self.scripts pkgs ./scripts) # Little utility programs.
      ++ [
        configs # Config files for some of the programs in this list.

        # Shells.
        (writeShellScriptBin "shell" ''$HOME/.nix-profile/bin/fish "$@"'' // { pname = "shell"; version = fish.version; })
        blesh my-bash # See blesh note in config/bash/bashrc.sh
        (wrapBin ''_BIN_ -C "$HOME/.nix-profile/bin/_jeremy-shell-init fish | source" "$@"'' fish)
        (wrapBin ''ZDOTDIR=$HOME/.config/zsh _BIN_ "$@"'' zsh)

        # Undollar: ignore leading $'s from copy-pasted commands.
        (writeShellScriptBin "$" "\"$@\"" // { pname = "dollar"; version = "1"; })

        # Comma: run programs without installing them.
        (writeShellScriptBin "," "nix run nixpkgs#\"$1\" -- \"\${@:2}\"" // { pname = "comma"; version = "1"; })
        (writeShellScriptBin ",," "nix run github:numtide/nixpkgs-unfree/nixpkgs-unstable#\"$1\" -- \"\${@:2}\"" // { pname = "comma-unfree"; version = "1"; })

        man
        mypkgs.daylight

        jujutsu
        starship-jj.packages.${system}.starship-jj

        # Life on the command line.
        _1password-cli
        atuin                 # Shell history search and sync.
        bash-completion       # Tab-completion for a bunch of commands.
        (themed "BAT_THEME" "Catppuccin Latte" "Catppuccin Mocha"
         bat)                 # Display files, with syntax highlighting.
        calc                  # A simple arbitrary-precision calculator.
        coreutils             # Basic file, shell and text manipulation utilities.
        (themed "DELTA_FEATURES" "catppuccin-latte" "catppuccin-mocha"
         delta)               # Better git diffs.
        direnv                # Set environment variables per-project.
        eza                   # List files in the current directory.
        fd                    # Find file by name.
        gh                    # GitHub CLI.
        git                   # Track version history for text files.
        git-lfs               # Efficiently store large files in git.
        gnupg                 # gpg, I use it to sign git commits
        go                    # Run Go code.
        google-cloud-sdk      # Google Cloud CLI.
        htop                  # Show CPU + memory usage.
        httpie                # Create and execute HTTP queries.
        inetutils             # Ping.
        jq                    # Zoom in on large JSON objects.
        nix-direnv            # Optimized direnv+nix integration.
        (python3.withPackages # Run Python.
          (ps: with ps; [
            llm
            llm-ollama
            ipython      # Better Python repl than the default.
          ]))
        nodejs_22
        ripgrep               # Text search. (Phenomenal grep replacement.)
        starship              # Nice command prompt.
        vim                   # Edit text.
        watch                 # Run a command repeatedly.
        wget                  # Download files.
        zoxide                # A smarter cd command.
      ] ++ lib.optionals (system == "x86_64-linux") [
        file                  # Get high-level semantic info about a file.
        ghostty               # My terminal. Installed separately on macOS.
        obsidian
      ];
  };
}
