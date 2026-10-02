{ ... }:
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
}
