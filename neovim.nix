pkgs: vim-plugins:

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

  dart-vim-plugin = (pkgs.vimUtils.buildVimPluginFrom2Nix {
    pname = "dart-vim-plugin";
    version = "2019-05-03";
    src = pkgs.fetchFromGitHub {
      owner = "dart-lang";
      repo = "dart-vim-plugin";
      rev = "8ffc3e208c282f19afa237d343fa1533146bd2b4";
      sha256 = "1ypcn3212d7gzfgvarrsma0pvaial692f3m2c0blyr1q83al1pm8";
    };
  });

  hot-reload = (pkgs.vimUtils.buildVimPluginFrom2Nix {
    pname = "hot-reload";
    version = "2019-02-24";
    src = pkgs.fetchFromGitHub {
      owner = "reisub0";
      repo = "hot-reload.vim";
      rev = "3c4f9358aadd0e400c781bdbff8ef25542d7f729";
      sha256 = "0b0lv2in3b68lq4028cr0qn8wk5cjg98iak2a7h2invfh1q139dr";
    };
  });

  vim-fetch = (pkgs.vimUtils.buildVimPluginFrom2Nix {
    pname = "vim-fetch";
    version = "2019-04-03";
    src = pkgs.fetchFromGitHub {
      owner = "wsdjeg";
      repo = "vim-fetch";
      rev = "76c08586e15e42055c9c21321d9fca0677442ecc";
      sha256 = "0avcqjcqvxgj00r477ps54rjrwvmk5ygqm3qrzghbj9m1gpyp2kz";
    };
  });

  vim-numbertoggle = (pkgs.vimUtils.buildVimPluginFrom2Nix {
    pname = "numbertoggle";
    version = "2017-10-26";
    src = pkgs.fetchFromGitHub {
      owner = "jeffkreeftmeijer";
      repo = "vim-numbertoggle";
      rev = "cfaecb9e22b45373bb4940010ce63a89073f6d8b";
      sha256 = "1rrmvv7ali50rpbih1s0fj00a3hjspwinx2y6nhwac7bjsnqqdwi";
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
      customRC = "source $XDG_CONFIG_HOME/nvim/init.vim";
      packages.mine = with pkgs.vimPlugins; {
        start = [
          camelcasemotion
          ctrlp-vim
          dart-vim-plugin
          fzf-vim
          fzfWrapper
          hot-reload
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
        ] ++ vim-plugins;
      };
     };
  })
