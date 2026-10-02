{ username, host, lib, ... }:
{
  # Fix keyboard layout in tty
  console.useXkbConfig = true;

  services = {
    xserver = {
      enable = true;
      videoDrivers = lib.mkIf (host == "zephyrus") [
        "amdgpu"
        "nvidia"
      ];
      xkb.layout = "de";
    };

    displayManager.autoLogin = lib.mkIf (host == "zephyrus") {
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
