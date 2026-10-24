{ config, host, ... }:
let
  island = "${config.services.island.package}/bin/island";
  dpms =
    action:
    if host == "atlas" then
      "${config.home.homeDirectory}/.local/bin/atlas-remote dpms ${action}"
    else
      "hyprctl dispatch 'hl.dsp.dpms({ action = \"${action}\" })'";
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
        lock_cmd = "${island} lock --wait";
        before_sleep_cmd = "${island} lock --wait";
        after_sleep_cmd = dpms "enable";
        # Hold the sleep inhibitor until the compositor confirms the lock.
        inhibit_sleep = 3;
      };

      listener = [
        {
          timeout = timeouts.display;
          on-timeout = dpms "disable";
          on-resume = dpms "enable";
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
