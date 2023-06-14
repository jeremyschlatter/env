pkgs:
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
  })
