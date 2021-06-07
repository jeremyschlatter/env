pkgs:

let
  vim-unicoder = (pkgs.vimUtils.buildVimPluginFrom2Nix {
    pname = "unicoder.vim";
    version = "2019-04-01";
    src = pkgs.fetchFromGitHub {
      owner = "arthurxavierx";
      repo = "vim-unicoder";
      rev = "b360487430fac5e369433a597733588748eff663";
      sha256 = "1yvgcyaqcb2c2vdr70kg335s3bwyd9kz6liiqvfhyagf24s4pcgs";
    };
  });

in
  (pkgs.neovim.override {
    viAlias = true;
    vimAlias = true;
    configure = {
      customRC = ''
        set runtimepath^=~/.config/nvim/
        source ~/.config/nvim/init.vim
      '';
      packages.mine = with pkgs.vimPlugins; {
        start = [
          camelcasemotion
          ctrlp-vim
          fzf-vim
          fzfWrapper
          idris-vim
          # LanguageClient-neovim
          vim-better-whitespace
          vim-colors-solarized
          vim-commentary
          vim-fetch
          vim-go
          vim-nix
          vim-numbertoggle
          vim-toml
          vim-unicoder
        ];
      };
     };
  })
