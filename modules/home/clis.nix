{ pkgs, inputs, ... }:
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
    gnumake
    wl-clipboard
    xdg-utils
    btop
    fastfetch
    nodejs_24
    pnpm
    go
    opencode
    claude-code
  ];
}
