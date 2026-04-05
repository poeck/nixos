{ pkgs, inputs, ... }:
{
  home.packages = with pkgs; [
    # Audio settings
    pavucontrol
    # Cool resource monitor
    mission-center
    # Discord
    discord
    # Best backup app
    blinkdisk
    # Email client
    geary
    # Speech-to-text
    inputs.handy.packages.${pkgs.stdenv.hostPlatform.system}.default
    # Notion alternative
    affine
    # Torrents
    qbittorrent-enhanced
    # Legendary media player
    vlc
    # 2FA OTP Codes
    proton-authenticator
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
