{ pkgs, ... }:
{
  # Enable hyprland
  programs.hyprland = {
    enable = true;
  };

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    # Used for screen sharing
    config = {
      common.default = ["gtk"];
      hyprland.default = ["hyprland" "gtk"];
    };
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
      xdg-desktop-portal-hyprland
    ];
  };

  fonts.fontconfig = {
    enable = true;
    antialias = true;
    cache32Bit = true;
    hinting = {
      enable = true;
      autohint = true;
    };
  };
}
