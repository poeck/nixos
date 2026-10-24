{
  host,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  control = pkgs.writeShellApplication {
    name = "atlas-remote";
    runtimeInputs = [
      pkgs.python3
      pkgs.hyprland
      pkgs.systemd
    ];
    text = ''
      exec python3 ${../../../scripts/atlas-remote.py} "$@"
    '';
  };
  sunshineConfig =
    (pkgs.formats.keyValue { }).generate "sunshine-atlas.conf"
      osConfig.services.sunshine.settings;
in
{
  config = lib.mkIf (host == "atlas") {
    # Also works before a system rebuild updates /etc/profiles/per-user/paul.
    home.file.".local/bin/atlas-remote".source = "${control}/bin/atlas-remote";

    # Keep NixOS's Sunshine unit and its graphical-session lifecycle; only
    # replace the launch command to select the appropriate output each time.
    xdg.configFile."systemd/user/sunshine.service.d/atlas-remote.conf".text = ''
      [Service]
      ExecStart=
      ExecStart=${control}/bin/atlas-remote sunshine ${lib.getExe osConfig.services.sunshine.package} ${sunshineConfig}
    '';

    home.hyprdynamicmonitors.serviceOptions.ExecCondition = "${control}/bin/atlas-remote local";

    xdg.desktopEntries.atlas-remote = {
      name = "Atlas: Toggle remote desktop";
      comment = "Switch between three physical monitors and a virtual display";
      exec = "${control}/bin/atlas-remote toggle";
      icon = "preferences-desktop-remote-desktop";
      categories = [ "Utility" ];
      terminal = false;
    };
  };
}
