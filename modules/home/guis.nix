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
    # Best backup app
    blinkdisk
    # Email client
    geary
  ];

  home.file = {
    ".config/electron-flags.conf" = {
      # Force electron apps to use wayland
      text = ''
        --enable-features=UseOzonePlatform
        --ozone-platform=wayland
      '';
    };
  };
}
