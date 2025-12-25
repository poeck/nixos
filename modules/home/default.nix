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
    ./hyprland # window manager
    ./nemo.nix # file manager
    ./nvim # neovim editor
    ./ssh.nix # ssh config
    ./notifications # notification center
    ./vicinae.nix # launcher
    ./waybar # status bar
    ./xdg.nix # xdg config
    ./alacritty.nix # terminal
    ./zsh # shell
    ./tmux # terminal splits
  ];
}
