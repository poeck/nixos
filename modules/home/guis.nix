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
    # Cursor editor
    code-cursor
    # Helium browser
    helium
    # Best backup app
    blinkdisk
  ];
}
