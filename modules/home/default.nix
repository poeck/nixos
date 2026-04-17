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
    ./nemo.nix # file manager
    ./ssh.nix # ssh config
    ./notifications # notification center
    ./xdg.nix # xdg config
    ./zsh.nix # shell
    ./hyprland # window manager
    ./waybar # status bar
    ./nvim # neovim editor
    ./alacritty # terminal
    ./tmux # terminal splits
    ./chromium.nix # chromium
    ./zed.nix # text editor
    ./claude-code.nix # claude code
    ./vicinae.nix # app launcher
  ];
}
