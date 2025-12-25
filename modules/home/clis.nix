{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ripgrep
    ffmpeg
    file
    jq
    killall
    libnotify
    openssl
    pamixer
    playerctl
    udiskie
    unzip
    wget
    wl-clipboard 
    xdg-utils
    btop
    fastfetch
    nodejs_24
    pnpm
  ];
}
