{ ... }:
{
  xdg.configFile."hypr/hypr_settings.lua".text = ''
    hl.config({
      input = {
        kb_layout = "de",
        numlock_by_default = true,
        repeat_delay = 300,
        follow_mouse = 2,
        accel_profile = "flat",
        sensitivity = -0.2,
        touchpad = {
          natural_scroll = true,
          disable_while_typing = true,
          scroll_factor = 0.2,
        },
      },

      -- Render the pointer in the compositor output so screen-sharing can capture it.
      cursor = {
        no_hardware_cursors = 1,
      },

      general = {
        layout = "dwindle",
        gaps_in = 7,
        gaps_out = 7,
        border_size = 2,
        col = {
          active_border = {
            colors = { "rgba(ffffffaa)", "rgba(ffffffaa)" },
            angle = 45,
          },
          inactive_border = "rgba(595959aa)",
        },
        resize_on_border = false,
        allow_tearing = true,
      },

      misc = {
        disable_hyprland_logo = true,
        always_follow_on_dnd = true,
        layers_hog_keyboard_focus = true,
        animate_manual_resizes = false,
        enable_swallow = true,
        focus_on_activate = true,
        on_focus_under_fullscreen = 2,
        middle_click_paste = false,
      },

      dwindle = {
        force_split = 2,
        special_scale_factor = 1.0,
        split_width_multiplier = 1.0,
        use_active_for_splits = true,
        preserve_split = true,
      },

      master = {
        new_status = "master",
      },

      decoration = {
        rounding = 8,
        blur = {
          enabled = true,
          size = 3,
          passes = 2,
          brightness = 1,
          contrast = 1.4,
          ignore_opacity = true,
          noise = 0,
          new_optimizations = true,
          xray = true,
        },
        shadow = {
          enabled = true,
          offset = { 0, 2 },
          range = 20,
          render_power = 3,
          color = "rgba(00000055)",
        },
      },

      animations = {
        enabled = true,
      },

      binds = {
        movefocus_cycles_fullscreen = true,
      },
    })

    hl.device({
      name = "asup1207:00-093a:3012-touchpad",
      sensitivity = 0,
    })

    hl.curve("easeOutQuint", {
      type = "bezier",
      points = { { 0.23, 1 }, { 0.32, 1 } },
    })
    hl.curve("easeInOutCubic", {
      type = "bezier",
      points = { { 0.65, 0.05 }, { 0.36, 1 } },
    })
    hl.curve("linear", {
      type = "bezier",
      points = { { 0, 0 }, { 1, 1 } },
    })
    hl.curve("almostLinear", {
      type = "bezier",
      points = { { 0.5, 0.5 }, { 0.75, 1.0 } },
    })
    hl.curve("quick", {
      type = "bezier",
      points = { { 0.15, 0 }, { 0.1, 1 } },
    })

    hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
    hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
    hl.animation({ leaf = "windows", enabled = true, speed = 4.79, bezier = "easeOutQuint" })
    hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, bezier = "easeOutQuint", style = "popin 87%" })
    hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
    hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
    hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
    hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
    hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
    hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
    hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
    hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
    hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
    hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94, bezier = "almostLinear", style = "slidefadevert" })
    hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1.21, bezier = "almostLinear", style = "slidefadevert" })
    hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "slidefadevert" })
  '';
}
