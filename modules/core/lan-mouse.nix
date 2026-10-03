{
  config,
  host,
  lib,
  pkgs,
  username,
  ...
}:
{
  networking.firewall.interfaces.${config.services.tailscale.interfaceName}.allowedUDPPorts = [
    4242
  ];

  # Run before systemd-sleep freezes user.slice. Stopping a user service from
  # /lib/systemd/system-sleep would happen too late and can deadlock.
  systemd.services.lan-mouse-before-sleep = lib.mkIf (host == "atlas") {
    description = "Disable Lan Mouse sharing before sleep";
    wantedBy = [ "sleep.target" ];
    before = [ "sleep.target" ];
    unitConfig.StopWhenUnneeded = true;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.systemd}/bin/systemctl --user --machine=${username}@.host stop lan-mouse.service
    '';
  };
}
