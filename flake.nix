{
  description = "Jeremy Schlatter's personal dev environment";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixpkgs-unstable;
    crane.url = github:ipetkov/crane;
  };

  outputs = { self, nixpkgs, crane }: {

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
        aarch64-linux = env "aarch64-linux";
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
        configs = self.copyDir pkgs "my-configs" ./config "$out/config";
        my-bash = writeShellScriptBin "bash" ''exec ${bashInteractive}/bin/bash --rcfile ${./config/bash/bashrc.sh} "$@"'';
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

                # Sadly I can't use withAllGrammars here, because it won't build on macOS:
                #   sandbox-exec: pattern serialization length 70022 exceeds maximum (65535)
                # See https://github.com/NixOS/nix/issues/4119.
                # Could be worked around by dropping the bundled-environment approach and
                # splitting up my installed packages.
                #
                # nvim-treesitter.withAllGrammars
                (nvim-treesitter.withPlugins (p: with p; [
                  c
                  vimdoc
                  lua
                  rust
                  go
                  nix
                  toml
                  nickel
                  python
                ]))

                nvim-solarized-lua
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
      in

      super ++ [
        configs # Config files for some of the programs in this list.
        (self.scripts pkgs ./scripts) # Little utility programs.

        # Shells.
        (writeShellScriptBin "shell" ''$HOME/.nix-profile/bin/fish "$@"'')
        blesh my-bash # See blesh note in config/bash/bashrc.sh
        (wrapBin ''_BIN_ -C "$HOME/.nix-profile/bin/_jeremy-shell-init fish | source"'' fish)
        (wrapBin ''ZDOTDIR=$HOME/.config/zsh _BIN_'' zsh)

        # Undollar: ignore leading $'s from copy-pasted commands.
        (writeShellScriptBin "$" "\"$@\"")
        (writeShellScriptBin "," "nix run nixpkgs#\"$1\" -- \"\${@:2}\"")

        man
        talosctl

        # AI stuff
        (ollama.overrideAttrs (oldAttrs: rec {
          version = "0.5.11";
          src = oldAttrs.src.override {
            tag = "v${version}";
            hash = "sha256-Yc/FwIoPvzYSxlrhjkc6xFL5iCunDYmZkG16MiWVZck=";
          };
          vendorHash = "sha256-wtmtuwuu+rcfXsyte1C4YLQA4pnjqqxFmH1H18Fw75g=";
          preBuild = "";
          doCheck = false;
          ldflags = oldAttrs.ldflags ++ [
            "-X=github.com/ollama/ollama/version.Version=${version}"
          ];
          patches = [(
            fetchpatch {
              url = "https://github.com/ollama/ollama/pull/9079.diff";
              hash = "sha256-63m9OY8uSWjiE9bs9Ry9RmDEQjsN0p8seTcFgHsEL+4=";
            }
          )];
        }))

        # Life on the command line.
        _1password-cli
        (atuin.overrideAttrs (oldAttrs: {
          patches = oldAttrs.patches ++ [./atuin.patch];
        }))                   # Shell history search and sync.
        bash-completion       # Tab-completion for a bunch of commands.
        (bat-themed bat)      # Display files, with syntax highlighting.
        calc                  # A simple arbitrary-precision calculator.
        coreutils             # Basic file, shell and text manipulation utilities.
        (bat-themed delta)    # Better git diffs.
        direnv                # Set environment variables per-project.
        eza                   # List files in the current directory.
        fd                    # Find file by name.
        fira-code             # Font that renders symbols in code nicely.
        gh                    # GitHub CLI.
        git                   # Track version history for text files.
        gnupg                 # gpg, I use it to sign git commits
        go                    # Run Go code.
        google-cloud-sdk      # Google Cloud CLI.
        gotools               # Tools to facilitate coding in Go.
        htop                  # Show CPU + memory usage.
        httpie                # Create and execute HTTP queries.
        inetutils             # Ping.
        jq                    # Zoom in on large JSON objects.
        nix-direnv            # Optimized direnv+nix integration.
        nix-index             # Find which nix package has the program you need.
        (python3.withPackages # Run Python.
          (ps: [ps.ipython])) # Better Python repl than the default.
        ripgrep               # Text search. (Phenomenal grep replacement.)
        starship              # Nice command prompt.
        uv
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
