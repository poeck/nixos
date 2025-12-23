{ pkgs, ... }:
{
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    # Common fonts
    corefonts
    vista-fonts
    # Symbols
    nerd-fonts.symbols-only
    # Terminal font
    nerd-fonts.jetbrains-mono
    # Swaybar
    nerd-fonts.agave
    # UI font
    cantarell-fonts
  ];

  gtk = {
    enable = true;
    colorScheme = "dark";
    font = {
      name = "Cantarell Regular";
      size = 11;
    };
    theme = {
      name = "Colloid-Green-Dark-Gruvbox";
      package = pkgs.colloid-gtk-theme.override {
        colorVariants = [ "dark" ];
        themeVariants = [ "green" ];
        tweaks = [
          "gruvbox"
          "rimless"
          "float"
        ];
      };
    };
    cursorTheme = {
      name = "Bibata-Modern-Ice";
      package = pkgs.bibata-cursors;
      size = 24;
    };
  };

  home.pointerCursor = {
    name = "Bibata-Modern-Ice";
    package = pkgs.bibata-cursors;
    size = 24;
  };
}
