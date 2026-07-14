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
    (python3.withPackages (
      python-pkgs: with python-pkgs; [
        pip
      ]
    ))
    nodejs_24
    pnpm
    go
    gh
    llm-agents.claude-code
    llm-agents.codex
    glab
  ];
}
