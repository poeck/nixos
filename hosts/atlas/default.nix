{ username, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./graphics.nix
    ../../modules/core
    ../../modules/core/media.nix
  ];

  # Desktop: no ASUS laptop daemon, TLP, or laptop-specific ACPI modules.
  powerManagement.enable = true;
  services.power-profiles-daemon.enable = true;
  services.system76-scheduler.settings.cfsProfiles.enable = true;

  networking.firewall.allowedTCPPorts = [ 8765 ];

  # Log in on tty1 and start Hyprland directly, without a display manager.
  services.getty = {
    autologinUser = username;
    autologinOnce = true;
  };
  home-manager.users.${username}.programs.zsh.profileExtra = ''
    if [[ -z "$DISPLAY" && -z "$WAYLAND_DISPLAY" && "$(tty)" == "/dev/tty1" ]]; then
      exec /run/current-system/sw/bin/Hyprland
    fi
  '';
}
