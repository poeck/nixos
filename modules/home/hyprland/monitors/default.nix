{ inputs, pkgs, ... }:
let
  applyMonitorConfig = pkgs.writeShellApplication {
    name = "apply-hypr-monitor-config";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.hyprland
      pkgs.gnused
    ];
    text = ''
      config_file="''${1:-$HOME/.config/hypr/monitors.conf}"
      generated_file="''${2:-$HOME/.config/hypr/generated_monitors.lua}"
      [[ -r "$config_file" ]] || exit 0

      generated_tmp="$(mktemp)"
      trap 'rm -f "$generated_tmp"' EXIT

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

          printf '%s\n' "$lua" >> "$generated_tmp"
          hyprctl eval "$lua"
        fi
      done < <(sed -n 's/^[[:space:]]*monitor[[:space:]]*=[[:space:]]*//p' "$config_file")

      install -Dm600 "$generated_tmp" "$generated_file"
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

  # HyprDynamicMonitors still generates legacy monitor lines. The helper above
  # translates and saves the selected profile as Lua, so every Hyprland reload
  # reapplies that profile instead of racing it with a scale-1 fallback.
  xdg.configFile."hypr/hypr_monitors.lua".text = ''
    local configHome = os.getenv("XDG_CONFIG_HOME")
    if configHome == nil or configHome == "" then
      configHome = os.getenv("HOME") .. "/.config"
    end

    local loaded = pcall(dofile, configHome .. "/hypr/generated_monitors.lua")
    if not loaded then
      hl.monitor({
        output = "",
        mode = "preferred",
        position = "auto",
        scale = 1,
      })
    end
  '';

  home.file = {
    ".config/hyprdynamicmonitors/profiles/" = {
      source = ./profiles;
    };
  };
}
