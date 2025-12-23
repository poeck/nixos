{ config, ... }:
{
  programs.tmux = {
    enable = true;
  };

  home.file = {
    ".tmux.conf" = {
      source = config.lib.file.mkOutOfStoreSymlink ./.tmux.conf;
    };
  };
}
