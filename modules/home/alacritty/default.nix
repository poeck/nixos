{ config, ... }:
{
  programs.alacritty = {
    enable = true;
  };

  home.file = {
    ".config/alacritty/alacritty.toml" = {
      source = config.lib.file.mkOutOfStoreSymlink ./alacritty.toml;
    };
  };
}
