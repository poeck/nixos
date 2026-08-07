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

      while IFS= read -r monitor; do
        if [[ -n "$monitor" ]]; then
          hyprctl keyword monitor "$monitor"
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
