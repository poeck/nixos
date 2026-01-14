{ pkgs, ... }:
{
  programs.gamescope = {
    enable = true;
  };

  programs.steam = {
    enable = true;
  };

  programs.gamemode.enable = true;

  environment.systemPackages = with pkgs; [
    gamescope-wsi
  ];
}
