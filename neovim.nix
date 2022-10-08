pkgs:
let
  leap = (pkgs.vimUtils.buildVimPluginFrom2Nix {
    pname = "leap.nvim";
    version = "2022-08-01";
    src = pkgs.fetchFromGitHub {
      owner = "ggandor";
      repo = "leap.nvim";
      rev = "5a09c30bf676d1392ff00eb9a41e0a1fc9b60a1b";
      sha256 = "sha256-xmqb3s31J1UxifXauBzBo5EkhafBEnq2YUYKRXJLGB0=";
    };
  });
in
  (pkgs.neovim.override {
    viAlias = true;
    vimAlias = true;
    configure = {
      customRC = ''
        set runtimepath^=~/.config/nvim/
        source ~/.config/nvim/init.lua
      '';
      packages.mine = with pkgs.vimPlugins; {
        start = [

          NeoSolarized
          camelcasemotion
          ctrlp-vim
          fzf-vim
          fzfWrapper
          leap
          rust-vim
          vim-better-whitespace
          vim-commentary
          vim-fetch
          vim-go
          vim-nix
          vim-numbertoggle
          vim-repeat
          vim-solidity
          vim-toml
          vim-unicoder

        ];
      };
     };
  })
