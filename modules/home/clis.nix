{ config, pkgs, ... }:
{
  home.sessionVariables = {
    NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.npm-global";
    PNPM_HOME = "${config.xdg.dataHome}/pnpm";
  };

  home.sessionPath = [
    "${config.home.sessionVariables.NPM_CONFIG_PREFIX}/bin"
    "${config.home.sessionVariables.PNPM_HOME}/bin"
  ];

  home.packages = with pkgs; [
    acli
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
