{ pkgs, username, ... }:
{
  environment.systemPackages = with pkgs; [
    jellyfin
    jellyfin-web
    jellyfin-ffmpeg
    jellyfin-desktop
  ];

  services.jellyfin = {
    enable = true;
    openFirewall = true;
    user = username;
  };
}
