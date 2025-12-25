{ host, ... }:
{
  programs.hyprlock = {
    enable = true;

    settings = {
      general = {
        hide_cursor = true;
      };
      animations = {
        enabled = true;
        bezier = "linear, 1, 1, 0, 0";
        animation =  [
          "fadeIn, 1, 5, linear"
          "fadeOut, 1, 5, linear"
          "inputFieldDots, 1, 2, linear"
        ];
      };
    };
  };
}
