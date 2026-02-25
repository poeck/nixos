{ ... }:
{
  wayland.windowManager.hyprland.settings = {
    input = {
      kb_layout = "de";
      numlock_by_default = true;
      repeat_delay = 300;
      follow_mouse = 2;
      accel_profile = "flat";
      sensitivity = -0.2;
      touchpad = {
        natural_scroll = true;
        disable_while_typing = true;
        scroll_factor = 0.2;
      };
    };

    device = {
      name = "asup1207:00-093a:3012-touchpad";
      sensitivity = 0;
    };

    "$mainMod" = "SUPER";

    general = {
      "$mainMod" = "SUPER";
      layout = "dwindle";
      gaps_in = 7;
      gaps_out = 7;
      border_size = 2;
      "col.active_border" = "rgba(ffffffaa) rgba(ffffffaa) 45deg";
      "col.inactive_border" = "rgba(595959aa)";
      resize_on_border = false;
      allow_tearing = true;
    };

    misc = {
      disable_hyprland_logo = true;
      always_follow_on_dnd = true;
      layers_hog_keyboard_focus = true;
      animate_manual_resizes = false;
      enable_swallow = true;
      focus_on_activate = true;
      on_focus_under_fullscreen = 2;
      middle_click_paste = false;
    };

    dwindle = {
      force_split = 2;
      special_scale_factor = 1.0;
      split_width_multiplier = 1.0;
      use_active_for_splits = true;
      pseudotile = "yes";
      preserve_split = "yes";
    };

    master = {
      new_status = "master";
    };

    decoration = {
      rounding = 8;

      blur = {
        enabled = true;
        size = 3;
        passes = 2;
        brightness = 1;
        contrast = 1.4;
        ignore_opacity = true;
        noise = 0;
        new_optimizations = true;
        xray = true;
      };

      shadow = {
        enabled = true;

        ignore_window = true;
        offset = "0 2";
        range = 20;
        render_power = 3;
        color = "rgba(00000055)";
      };
    };

    animations = {
      enabled = true;

      bezier = [
        "easeOutQuint,0.23,1,0.32,1"
        "easeInOutCubic,0.65,0.05,0.36,1"
        "linear,0,0,1,1"
        "almostLinear,0.5,0.5,0.75,1.0"
        "quick,0.15,0,0.1,1"
      ];

      animation = [
        "global,1,10,default"
        "border,1,5.39,easeOutQuint"
        "windows,1,4.79,easeOutQuint"
        "windowsIn,1,4.1,easeOutQuint,popin 87%"
        "windowsOut,1,1.49,linear,popin 87%"
        "fadeIn,1,1.73,almostLinear"
        "fadeOut,1,1.46,almostLinear"
        "fade,1,3.03,quick"
        "layers,1,3.81,easeOutQuint"
        "layersIn,1,4,easeOutQuint,fade"
        "layersOut,1,1.5,linear,fade"
        "fadeLayersIn,1,1.79,almostLinear"
        "fadeLayersOut,1,1.39,almostLinear"
        "workspaces,1,1.94,almostLinear,slidefadevert"
        "workspacesIn,1,1.21,almostLinear,slidefadevert"
        "workspacesOut,1,1.94,almostLinear,slidefadevert"
      ];
    };
  };
}
