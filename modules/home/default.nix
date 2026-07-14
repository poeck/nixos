{ ... }:
{
  imports = [
    # Custom scripts
    ./scripts/scripts.nix

    # Groups
    ./clis.nix # clis
    ./guis.nix # clis

    ./fzf.nix # fuzzy finder
    ./git.nix # version control
    ./gnome.nix # gnome apps
    ./gtk.nix # gtk theme
    ./easyeffects.nix # audio effects
    ./oo7.nix # secret service
    ./nautilus.nix # file manager
    ./ssh.nix # ssh config
    ./notifications # notification center
    ./xdg.nix # xdg config
    ./zsh.nix # shell
    ./hyprland # window manager
    ./noctalia # status bar / shell
    ./alacritty # terminal
    ./tmux # terminal splits
    ./chromium.nix # chromium
    ./zen.nix # zen browser
    ./zed.nix # text editor
    ./claude-code.nix # claude code
    ./codex-desktop.nix # codex desktop app
    ./vicinae.nix # app launcher
    ./laptop-control.nix # local network power controls
  ];
}
