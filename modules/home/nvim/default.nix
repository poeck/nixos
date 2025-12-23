{ config, pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
  };

  home.file = {
    ".config/nvim" = {
      source = config.lib.file.mkOutOfStoreSymlink ./config;
    };
  };

  xdg.dataFile."nvim/site/autoload/plug.vim".source = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/junegunn/vim-plug/3f17a5cc3d7b0b7699bb5963fef9435a839dada0/plug.vim";
    sha256 = "sha256-4JmeVzBIZedfWxXuhjfcTOW6lZF1V/OPfLY9RUtTz7Q=";
  };
}
