{ username, ... }:
{
  # Fix keyboard layout in tty
  console.useXkbConfig = true;

  services = {
    xserver = {
      enable = true;
      videoDrivers = [
        "amdgpu"
        "nvidia"
      ];
      xkb.layout = "de";
    };

    displayManager.autoLogin = {
      enable = true;
      user = "${username}";
    };

    libinput = {
      enable = true;
    };
  };

  # Fix to prevent getting stuck at shutdown
  systemd.settings.Manager.DefaultTimeoutStopSec = "10s";
}
