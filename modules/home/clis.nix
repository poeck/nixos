{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ripgrep
    ffmpeg
    file
    jq
    libnotify
    openssl
    pamixer
    playerctl
    udiskie
    unzip
    gnumake
    wl-clipboard
    xdg-utils
    btop
    fastfetch
    nodejs_24
    pnpm
    go
    gh
    llm-agents.claude-code
    llm-agents.codex
  ];
}
