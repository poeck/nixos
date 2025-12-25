{ config, pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    extraConfig = ''
      source $HOME/.config/nvim/plugins.vim
      source $HOME/.config/nvim/options.vim
      source $HOME/.config/nvim/mappings.vim
      source $HOME/.config/nvim/vars.vim
      source $HOME/.config/nvim/functions.vim
      source $HOME/.config/nvim/other.vim
    '';
  };

  home.file = {
    ".config/nvim/plugins.vim" = {
      source = config.lib.file.mkOutOfStoreSymlink ./config/plugins.vim;
    };
    ".config/nvim/options.vim" = {
      source = config.lib.file.mkOutOfStoreSymlink ./config/options.vim;
    };
    ".config/nvim/mappings.vim" = {
      source = config.lib.file.mkOutOfStoreSymlink ./config/mappings.vim;
    };
    ".config/nvim/vars.vim" = {
      source = config.lib.file.mkOutOfStoreSymlink ./config/vars.vim;
    };
    ".config/nvim/functions.vim" = {
      source = config.lib.file.mkOutOfStoreSymlink ./config/functions.vim;
    };
    ".config/nvim/other.vim" = {
      source = config.lib.file.mkOutOfStoreSymlink ./config/other.vim;
    };
    ".config/nvim/vscode.vim" = {
      source = config.lib.file.mkOutOfStoreSymlink ./config/vscode.vim;
    };
    ".config/nvim/coc-settings.json" = {
      source = config.lib.file.mkOutOfStoreSymlink ./config/coc-settings.json;
    };
    ".config/nvim/lua" = {
      source = config.lib.file.mkOutOfStoreSymlink ./config/lua;
    };
  };

  xdg.dataFile."nvim/site/autoload/plug.vim".source = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/junegunn/vim-plug/3f17a5cc3d7b0b7699bb5963fef9435a839dada0/plug.vim";
    sha256 = "sha256-4JmeVzBIZedfWxXuhjfcTOW6lZF1V/OPfLY9RUtTz7Q=";
  };
}
