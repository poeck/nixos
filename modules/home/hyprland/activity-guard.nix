{
  host,
  lib,
  pkgs,
  ...
}:
let
  guard = pkgs.writeShellApplication {
    name = "atlas-activity-guard";
    runtimeInputs = [
      pkgs.python3
      pkgs.systemd
      pkgs.t3-cli
    ];
    text = ''
      exec python3 ${../../../scripts/atlas-activity-guard.py} "$@"
    '';
  };
in
{
  config = lib.mkIf (host == "atlas") {
    home.packages = [ guard ];
    home.file.".local/bin/atlas-activity-guard".source = "${guard}/bin/atlas-activity-guard";

    # This separate timer survives a stopped/crashed main monitor. The idle
    # marker is set only after Hypridle's normal 30-minute desktop timeout.
    systemd.user.timers.atlas-activity-fallback = {
      Unit = {
        Description = "Fall back to normal idle suspend if the T3 monitor stops";
        PartOf = [ "graphical-session.target" ];
      };
      Timer = {
        OnActiveSec = 60;
        OnUnitActiveSec = 60;
        AccuracySec = 1;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
    systemd.user.services.atlas-activity-fallback = {
      Unit.Description = "Check the T3 activity monitor heartbeat";
      Service = {
        Type = "oneshot";
        ExecStart = "${guard}/bin/atlas-activity-guard fallback";
        UMask = "0077";
        NoNewPrivileges = true;
      };
    };

    systemd.user.services.atlas-activity-guard = {
      Unit = {
        Description = "Keep Atlas awake while T3 Code MCP reports active work";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${guard}/bin/atlas-activity-guard run";
        Restart = "on-failure";
        RestartSec = 5;
        UMask = "0077";
        NoNewPrivileges = true;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
