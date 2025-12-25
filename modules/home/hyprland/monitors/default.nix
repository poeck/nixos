{ config, inputs, pkgs, username, ... }:
{
  imports = [ inputs.hyprdynamicmonitors.homeManagerModules.default ];

  home.hyprdynamicmonitors = {
    enable = true;
    configFile = ./config.toml;
  };

  home.file = {
    ".config/hyprdynamicmonitors/profiles/" = {
      source = config.lib.file.mkOutOfStoreSymlink ./profiles;
    };
  };
}
