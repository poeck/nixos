{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # GUI for gnome-keyring
    seahorse
    # Audio settings
    pavucontrol
    # Simple calculator
    gnome-calculator
    # Cool resource monitor
    mission-center
    # Discord
    discord
    # Helium browser
    helium
    # Cursor editor
    code-cursor
  ];
}
