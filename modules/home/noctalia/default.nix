{ ... }:
{
  programs.noctalia = {
    enable = true;

    # Official Monokai Pro / Monokai Pro Light colors (from monokai.pro).
    customPalettes.MonokaiPro = ./monokai-pro.json;

    settings = {
      theme = {
        source = "custom";
        custom_palette = "MonokaiPro";
        templates.builtin_ids = [ "hyprland" ];
      };

      shell = {
        # Noctalia acts as the polkit authentication agent (replaces Soteria).
        polkit_agent = true;
        lang = "en";
        font_family = "Cantarell";
        external_ip_enabled = true;
        screen_time_enabled = true;
        animation.speed = 1.5;
        screen_corners = {
          enabled = true;
          size = 25;
        };
        screenshot = {
          annotate = true;
          directory = "~/Pictures/Screenshots";
        };
      };

      # The wallpaper is drawn by swaybg (see Hyprland exec-once).
      wallpaper.enabled = false;

      location.auto_locate = true;

      # Google accounts authorize per device via Settings → Calendar → Accounts → Connect.
      calendar = {
        enabled = true;
        account = {
          personal_google = {
            type = "google";
            name = "Personal Calendar";
            color = "primary";
          };
          otark_google = {
            type = "google";
            name = "Otark";
            color = "secondary";
          };
        };
      };

      control_center.hidden_tabs = [
        "media"
        "monitor"
      ];

      desktop_widgets.enabled = false;

      dock = {
        # Hidden by default; Super + D toggles it and Noctalia remembers the choice.
        enabled = false;
        background_opacity = 1.0;
        border_width = 1.0;
        margin_edge = 28;
        reserve_space = false;
        show_dots = true;
      };

      bar.default = {
        # Full-width bar with square corners.
        margin_ends = 0;
        radius = 0;
        concave_edge_corners = false;

        # Keep the bar visible and reserve space so windows stay below it.
        auto_hide = false;
        smart_auto_hide = false;
        reserve_space = true;
        show_on_workspace_switch = false;

        start = [
          "launcher"
          "workspaces"
        ];
        center = [ "clock" ];
        end = [
          "tray"
          "network"
          "bluetooth"
          "volume"
          "brightness"
          "battery"
          "control-center"
          "notifications"
          "session"
        ];
      };

      widget = {
        # Numbered pills for this monitor's workspaces; the active one is highlighted.
        workspaces = {
          show_labels = true;
          labels_only_when_occupied = false;
          hide_when_empty = false;
          show_all_outputs = false;
        };

        clock = {
          format = "{:%A, %d. %B %Y  ·  %H:%M}";
          tooltip_format = "{:%A, %d. %B %Y}";
        };

        # Collapse tray icons into a drawer to keep the bar tidy.
        tray = {
          drawer = true;
          hide_passive = true;
        };

        network.show_label = false;
        bluetooth.show_label = false;
        volume.show_label = true;
        notifications.hide_when_no_unread = false;
      };
    };
  };
}
