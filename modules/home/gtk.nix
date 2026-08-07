{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Symbols
    nerd-fonts.symbols-only
    # Terminal font
    nerd-fonts.jetbrains-mono
    # Swaybar
    nerd-fonts.agave
    # UI font
    cantarell-fonts
  ];

  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      sansSerif = [ "Cantarell" ];
      monospace = [ "JetBrainsMono Nerd Font Mono" ];
    };
  };

  gtk = {
    enable = true;
    colorScheme = "dark";
    gtk4.theme = null;
    font = {
      name = "Cantarell Regular";
      size = 11;
    };
    theme = {
      name = "gruvbox-dark";
      package = pkgs.gruvbox-dark-gtk;
    };
    cursorTheme = {
      name = "Bibata-Modern-Ice";
      package = pkgs.bibata-cursors;
      size = 24;
    };
  };

  home.pointerCursor = {
    enable = true;
    name = "Bibata-Modern-Ice";
    package = pkgs.bibata-cursors;
    size = 24;
  };
}
