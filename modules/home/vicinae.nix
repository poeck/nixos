{ pkgs, ... }:
let
  # Vicinae 0.23 still emits Hyprland's legacy
  # `hyprctl dispatch exec -- <command>` syntax. In Lua config mode Hyprland
  # expects an exec dispatcher expression instead, so translate only that
  # invocation and leave every other hyprctl command untouched.
  hyprctlCompat = pkgs.writeShellScriptBin "hyprctl" ''
    if [[ "$#" -ge 2 && "$1" == "dispatch" && "$2" == "exec" ]]; then
      shift 2
      if [[ "''${1-}" == "--" ]]; then
        shift
      fi

      printf -v command '%q ' "$@"
      command="''${command% }"
      luaString="$(${pkgs.jq}/bin/jq -Rn --arg command "$command" '$command')"
      exec ${pkgs.hyprland}/bin/hyprctl dispatch "hl.dsp.exec_cmd($luaString)"
    fi

    exec ${pkgs.hyprland}/bin/hyprctl "$@"
  '';
in
{
  home.packages = [ pkgs.vicinae ];

  systemd.user.services.vicinae = {
    Unit = {
      Description = "Vicinae launcher server";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Environment = [
        "PATH=${hyprctlCompat}/bin:/run/wrappers/bin:/etc/profiles/per-user/paul/bin:/run/current-system/sw/bin"
      ];
      ExecStart = "${pkgs.vicinae}/bin/vicinae server";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
