{ host, ... }:
{
  programs.hyprlock = {
    enable = true;

    settings = {
      general = {
        hide_cursor = true;
      };

      background = [
        {
          monitor = "";
          path = "${../../../wallpaper.jpg}";
          blur_passes = 3;
        }
      ];

      input-field = [
        {
          size = "20%, 5%";
          outline_thickness = 2;
          rounding = 10;
          inner_color = "rgba(255, 255, 255, 0.15)";
          outer_color = "rgba(255, 255, 255, 0.3)";
          check_color = "rgba(00ff99ee) rgba(ff6633ee) 120deg";
          fail_color = "rgba(ff6633ee) rgba(ff0066ee) 40deg";
          fade_on_empty = false;
          font_color = "rgb(255, 255, 255)";
          font = "JetBrainsMono Nerd Font Mono";
          placeholder_text = "Input password";
          fail_text = "$PAMFAIL";
          dots_spacing = 0.5;
          position = "0, -20";
          halign = "center";
          valign = "center";
        }
      ];

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
