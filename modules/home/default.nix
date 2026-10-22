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
    ./keyring.nix # secret service
    ./nautilus.nix # file manager
    ./ssh.nix # ssh config
    ./xdg.nix # xdg config
    ./zsh.nix # shell
    ./hyprland # window manager
    ./island.nix # status bar, launcher, notifications, authentication and lock screen
    ./alacritty # terminal
    ./tmux # terminal splits
    ./helium.nix # helium browser
    ./zed.nix # text editor
    ./claude-code.nix # claude code
    ./t3code.nix # T3 Code CLI and background server
    ./lan-mouse.nix # manual sharing on Atlas; receiver on Zephyrus
  ];
}
