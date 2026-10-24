{ pkgs, ... }:
let
  # Atlas's existing desktop user is UID 1000. Read only the marker's existence;
  # never execute or source anything from the user-writable runtime directory.
  marker = "/run/user/1000/atlas-remote/enabled";
  guard = pkgs.writeShellApplication {
    name = "atlas-remote-power-guard";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.systemd
    ];
    text = ''
      exec ${pkgs.bash}/bin/bash ${../../scripts/atlas-remote-power-guard.sh} \
        ${marker} /run/systemd/system
    '';
  };
in
{
  systemd.services.atlas-remote-power-guard = {
    description = "Protect Atlas against power-off while remote mode is enabled";
    # Also synchronize on boot/activation if the marker already exists.
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${guard}/bin/atlas-remote-power-guard";
      UMask = "0022";
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ReadWritePaths = [ "/run/systemd/system" ];
    };
  };

  systemd.paths.atlas-remote-power-guard = {
    description = "Watch Atlas remote mode for power-off protection";
    wantedBy = [ "multi-user.target" ];
    pathConfig = {
      # PathExists would repeatedly trigger the oneshot while enabled.
      PathChanged = marker;
      Unit = "atlas-remote-power-guard.service";
    };
  };
}
