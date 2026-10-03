{ host, ... }:
let
  timeouts =
    if host == "zephyrus" then
      {
        display = 13 * 60;
        lock = 14 * 60;
        suspend = 15 * 60;
      }
    else
      {
        display = 15 * 60;
        lock = 29 * 60;
        suspend = 30 * 60;
      };
in
{
  services.hypridle = {
    enable = true;

    settings = {
      general = {
        lock_cmd = "noctalia msg session lock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };

      listener = [
        {
          timeout = timeouts.display;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
        {
          timeout = timeouts.lock;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = timeouts.suspend;
          on-timeout = if host == "zephyrus" then "systemctl suspend-then-hibernate" else "systemctl suspend";
        }
      ];
    };
  };
}
