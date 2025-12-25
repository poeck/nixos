{ inputs, pkgs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  imports = [ inputs.vicinae.homeManagerModules.default ];

  services.vicinae = {
    enable = true;
    package = inputs.vicinae.packages.${system}.default;
    autoStart = false;
    useLayerShell = true;

    settings = {
      font = {
        normal = "JetBrainsMono Nerd Font Mono";
        size = 12;
      };

      theme = {
        iconTheme = "Papirus-Dark";
        name = "custom";
      };

      window = {
        csd = true;
        opacity = 1;
        rounding = 0;
      };

      faviconService = "twenty";
      popToRootOnClose = true;
      closeOnFocusLoss = true;
    };
  };
}
