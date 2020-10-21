pkgs:

let
  camelcasemotion = (pkgs.vimUtils.buildVimPluginFrom2Nix {
    pname = "camelcasemotion";
    version = "2011-11-11";
    src = pkgs.fetchFromGitHub {
      owner = "vim-scripts";
      repo = "camelcasemotion";
      rev = "8db17bdee3f42bd71839ead2a84b2ee1916e45c2";
      sha256 = "0qqykxqj393ig7ard7pvvc0h0k3x61gdyypcvnsm66g5fvr2cqxr";
    };
  });

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
      customRC = ":source $HOME/.config/nvim.vim";
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
