{
  description = "Jeremy Schlatter's personal dev environment";

  nixConfig = {
    extra-substituters = [ "https://jeremyschlatter-env.cachix.org" ];
    extra-trusted-public-keys = [ "jeremyschlatter-env.cachix.org-1:+nMBUkfZO2bJ3NWrTUU2VulOCcOutGkBQm0VCCyWoHo=" ];
  };

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

  outputs = { self, nixpkgs, crane, personal, starship-jj }:
  let
    forAllSystems = nixpkgs.lib.genAttrs [ "aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux" ];
    pkgsFor = system: import nixpkgs { inherit system; config.allowUnfree = true; };
  in {

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
    merge = flakes: forAllSystems (system:
      let pkgs = pkgsFor system;
      in with pkgs.lib; pkgs.buildEnv {
        name = "bundled-environment";
        paths = trivial.pipe []
          (lists.forEach flakes
            (flake: super: lists.flatten (flake.profile {
              inherit system pkgs super;
            })));
      });

    # Packages exposed by this flake.
    packages = forAllSystems (system:
      self.scripts (pkgsFor system) ./scripts // { default = (self.merge [self]).${system}; });

    # Legacy. As of 2026-01-20, all of my installed systems depend on this attribute name.
    # I'm leaving it here until such time as I update all of them.
    defaultPackage = forAllSystems (system: self.packages.${system}.default);

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
        skills = self.copyDir pkgs "my-skills" ./skills "$out/skills" // { pname = "my-skills"; version = "1"; };
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
        execToStr = cmd: builtins.readFile (runCommand "exec" {} "${cmd} > $out");
        ls-colors = let v = c: execToStr "${vivid}/bin/vivid generate catppuccin-${c}"; in
          themed "LS_COLORS" (v "latte") (v "mocha");
        mypkgs = personal.packages.${system};
        patch = pkg: patches: pkg.overrideAttrs (oldAttrs: {
          patches = (oldAttrs.patches or []) ++ patches;
        });
      in

      super
      ++ builtins.attrValues (self.scripts pkgs ./scripts) # Little utility programs.
      ++ [
        configs # Config files for some of the programs in this list.
        skills  # Claude Code skills.

        # Shells.
        (writeShellScriptBin "shell" ''$HOME/.nix-profile/bin/fish "$@"'' // { pname = "shell"; version = fish.version; })
        blesh my-bash # See blesh note in config/bash/bashrc.sh
        (wrapBin ''_BIN_ -C "$HOME/.nix-profile/bin/_jeremy-shell-init fish | source" "$@"'' fish)
        (wrapBin ''ZDOTDIR=$HOME/.config/zsh _BIN_ "$@"'' zsh)

        # Undollar: ignore leading $'s from copy-pasted commands.
        (writeShellScriptBin "$" "\"$@\"" // { pname = "dollar"; version = "1"; })

        # Comma: run programs without installing them.
        (writeShellScriptBin "," "nix run nixpkgs#\"$1\" -- \"\${@:2}\"" // { pname = "comma"; version = "1"; })
        (writeShellScriptBin ",." "nix shell nixpkgs#\"$1\" --command \"\${@:2}\"" // { pname = "comma-dot"; version = "1"; })
        (writeShellScriptBin ",," "nix run github:numtide/nixpkgs-unfree/nixpkgs-unstable#\"$1\" -- \"\${@:2}\"" // { pname = "comma-unfree"; version = "1"; })

        # sha1collisiondetection: a version of sha1sum that detects attacks like shattered.io
        # I'm adding a "sha1sum" wrapper around it (the upstream binary is called "sha1dcsum") to make it a true drop-in replacement.
        (writeShellScriptBin "sha1sum" "${sha1collisiondetection}/bin/sha1dcsum \"$@\"" // { pname = "sha1sum-alias"; version = "1"; })

        man
        mypkgs.daylight
        mypkgs.linear-cli

        jujutsu
        starship-jj.packages.${system}.starship-jj
        ast-grep
        btop

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
        (ls-colors eza)       # List files in the current directory.
        (ls-colors fd)        # Find file by name.
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
        # ghostty               # My terminal. Installed separately on macOS.
        # obsidian
      ] ++ lib.optionals stdenv.isDarwin [
        mypkgs.opcli          # Fast 1Password CLI (macOS only).
      ];
  };
}
