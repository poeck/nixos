{ pkgs, ... }:
{
  home.packages = (
    with pkgs;
    [
      evince # pdf
      file-roller # archive
      gnome-text-editor # gedit
    ]
  );

  dconf.settings = {
    "org/gnome/TextEditor" = {
      custom-font = "JetBrainsMono Nerd Font Mono 15";
      highlight-current-line = true;
      indent-style = "space";
      restore-session = false;
      show-grid = false;
      show-line-numbers = true;
      show-right-margin = false;
      tab-width = "uint32 4";
      use-system-font = false;
      wrap-text = false;
    };
  };
}
