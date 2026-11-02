{ pkgs, ... }:
{
  home.packages = with pkgs; [ nautilus ];

  dconf.settings = {
    "org/gnome/nautilus/preferences" = {
      default-folder-viewer = "grid-view";
      show-hidden-files = true;
      show-create-link = true;
      show-delete-permanently = true;
    };
  };
}
