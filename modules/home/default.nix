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
    ./vicinae.nix # launcher
    ./xdg.nix # xdg config
    ./hyprland # window manager
    ./waybar # status bar
    ./nvim # neovim editor
    ./zsh # shell
    ./alacritty # terminal
    ./tmux # terminal splits
    ./chromium.nix # chromium
  ];
}
