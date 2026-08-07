{ inputs, pkgs, ... }:
let
  applyMonitorConfig = pkgs.writeShellApplication {
    name = "apply-hypr-monitor-config";
    runtimeInputs = [
      pkgs.hyprland
      pkgs.gnused
    ];
    text = ''
      config_file="''${1:-$HOME/.config/hypr/monitors.conf}"
      [[ -r "$config_file" ]] || exit 0

      trim() {
        local value="$1"
        value="''${value#"''${value%%[![:space:]]*}"}"
        value="''${value%"''${value##*[![:space:]]}"}"
        printf '%s' "$value"
      }

      lua_string() {
        local value="$1"
        value="''${value//\\/\\\\}"
        value="''${value//\"/\\\"}"
        printf '%s' "$value"
      }

      while IFS= read -r monitor; do
        if [[ -n "$monitor" ]]; then
          IFS=',' read -r output mode position scale _transform_key transform _vrr_key vrr _bitdepth_key bitdepth _ <<< "$monitor"

          output="$(lua_string "$(trim "$output")")"
          mode="$(lua_string "$(trim "$mode")")"
          position="$(lua_string "$(trim "$position")")"
          scale="$(trim "$scale")"

          lua="hl.monitor({ output = \"$output\", mode = \"$mode\", position = \"$position\", scale = $scale"
          [[ -n "$transform" ]] && lua+=", transform = $(trim "$transform")"
          [[ -n "$vrr" ]] && lua+=", vrr = $(trim "$vrr")"
          [[ -n "$bitdepth" ]] && lua+=", bitdepth = $(trim "$bitdepth")"
          lua+=" })"

          hyprctl eval "$lua"
        fi
      done < <(sed -n 's/^[[:space:]]*monitor[[:space:]]*=[[:space:]]*//p' "$config_file")
    '';
  };
in
{
  imports = [ inputs.hyprdynamicmonitors.homeManagerModules.default ];

  home.hyprdynamicmonitors = {
    enable = true;
    serviceOptions.ExecStartPost = "${applyMonitorConfig}/bin/apply-hypr-monitor-config";
    config = ''
      [general]
      post_apply_exec = "${applyMonitorConfig}/bin/apply-hypr-monitor-config"

      ${builtins.readFile ./config.toml}
    '';
  };

  # HyprDynamicMonitors still generates legacy monitor lines. This fallback
  # starts every connected display safely; the service then applies the selected
  # profile through apply-hypr-monitor-config.
  xdg.configFile."hypr/hypr_monitors.lua".text = ''
    hl.monitor({
      output = "",
      mode = "preferred",
      position = "auto",
      scale = 1,
    })
  '';

  home.file = {
    ".config/hyprdynamicmonitors/profiles/" = {
      source = ./profiles;
    };
  };
}
