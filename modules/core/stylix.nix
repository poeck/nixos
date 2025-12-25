{ pkgs, inputs, ... }:
{
  imports = [
    inputs.stylix.nixosModules.stylix
  ];

  stylix.enable = true;
  
  stylix.image = ../../wallpaper.jpg;
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-material-dark-soft.yaml";
  stylix.polarity = "dark";

  stylix.targets.plymouth.enable = false;
  stylix.targets.grub.enable = false;

  stylix.cursor = {
    name = "Bibata-Modern-Ice";
    package = pkgs.bibata-cursors;
    size = 24;
  };

  environment.systemPackages = with pkgs; [
    # Common fonts
    corefonts
    vista-fonts
    # Swaybar
    nerd-fonts.agave
  ];

  stylix.fonts = {
    serif = {
      package = pkgs.cantarell-fonts;
      name = "Cantarell";
    };
    sansSerif = {
      package = pkgs.cantarell-fonts;
      name = "Cantarell";
    };
    monospace = {
      package = pkgs.nerd-fonts.jetbrains-mono;
      name = "JetBrainsMono Nerd Font Mono";
    };
    emoji = {
      package = pkgs.noto-fonts-color-emoji;
      name = "Noto Color Emoji";
    };
  };
}
