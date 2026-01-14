{ ... }:
{
  programs.waybar.settings.mainBar = {
    layer = "top";
    spacing = 3;
    height = 30;
    margin-top = 5;
    margin-right = 8;
    margin-bottom = 0;
    margin-left = 8;

    modules-left = [
      "tray"
      "mpris"
    ];
    modules-center = [ "clock" ];
    modules-right = [
      "cpu_text"
      "cpu"
      "memory"
      "battery"
      "network"
      "pulseaudio"
    ];

    tray = {
      spacing = 6;
      tooltip = false;
      icon-size = 16;
    };

    clock = {
      format = "{:%a %d, %I:%M %p}";
      tooltip = false;
    };

    cpu = {
      format = "  {usage}%";
      interval = 2;
      states = {
        critical = 70;
      };
    };

    memory = {
      format = "  {percentage}%";
      interval = 2;
      states = {
        critical = 80;
      };
    };

    battery = {
      format = "  {capacity}%";
      interval = 5;
      states = {
        warning = 20;
        critical = 10;
      };
      tooltip = false;
      on-double-click = "pkill waybar && waybar";
    };

    network = {
      format-wifi = "  up";
      format-ethernet = "󰈀  up";
      format-disconnected = "󰤯  dead";
      tooltip = false;
    };

    pulseaudio = {
      scroll-step = 5;
      max-volume = 150;
      format = "󰕾 {volume}%";
      format-bluetooth = "󰕾  {volume}%";
      nospacing = 1;
      on-click = "pavucontrol";
      tooltip = true;
    };

    mpris = {
      format = "{player_icon}  {dynamic}";
      format-paused = "{status_icon} <i>{dynamic}</i>";
      player-icons = {
        default = "";
        mpv = "";
      };
      status-icons = {
        paused = "⏸";
      };
      dynamic-order = [
        "title"
        "artist"
      ];
      dynamic-len = 30;
    };
  };
}
