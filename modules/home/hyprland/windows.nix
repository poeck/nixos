{ ... }:
{
  wayland.windowManager.hyprland.settings = {
    windowrule = [
      # Make file dialogs float
      "float on, match:class ^(file_progress)$"
      "float on, match:class ^(confirm)$"
      "float on, match:class ^(dialog)$"
      "float on, match:class ^(download)$"
      "float on, match:class ^(notification)$"
      "float on, match:class ^(error)$"
      "float on, match:class ^(confirmreset)$"
      "float on, match:title ^(Open File)$"
      "float on, match:title ^(File Upload)$"
      "float on, match:title ^(branchdialog)$"
      "float on, match:title ^(Confirm to replace files)$"
      "float on, match:title ^(File Operation Progress)$"

      # Screenshare picker
      "opacity 0.0 override, match:class ^(xwaylandvideobridge)$"
      "no_anim on, match:class ^(xwaylandvideobridge)$"
      "no_initial_focus on, match:class ^(xwaylandvideobridge)$"
      "max_size 1 1, match:class ^(xwaylandvideobridge)$"
      "no_blur on, match:class ^(xwaylandvideobridge)$"

      # Remove context menu transparency in chromium based apps
      "opaque on, no_shadow on, no_blur on, match:class ^()$, match:title ^()$"

      # Custom window rules
      # Gather
      "workspace special:gather, match:class (Gather)"
      # YouTube Music
      "workspace special:music, match:initial_title (YouTube Music)"

      "workspace 9 silent, match:class ^(cs2)$"
      "immediate on, match:class ^(cs2)$"
      "border_size 0, match:class ^(cs2)$"
      "rounding 0, match:class ^(cs2)$"

      "border_size 0, match:float 0, match:workspace f[1]"
      "rounding 0, match:float 0, match:workspace f[1]"
    ];

    layerrule = [
      # Vicinae launcher
      "blur on, ignore_alpha 0, no_anim on, dim_around on, match:namespace vicinae"

      # Add dim to notification center
      "dim_around on, match:namespace swaync-control-center"
    ];

    workspace = [
      # Disable gaps in fullscreen
      "f[1], gapsout:0, gapsin:0"
      "9, monitor:desc:Philips Consumer Electronics Company PHL 246E9Q 0x000036F7"
    ];
  };
}
