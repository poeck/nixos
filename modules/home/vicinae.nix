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
  };
}
