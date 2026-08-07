{ pkgs, inputs, ... }:
{
  home.packages =
    with pkgs;
    [
      # Wayland itself
      wayland
      # Screenshot tools
      grimblast
      grim
      slurp
      # Color picker
      hyprpicker
      # Persist on program close
      wl-clip-persist
      # Clipboard manager
      cliphist
      # Required by wayland (?)
      glib
      # Wallpaper
      swaybg
    ]
    ++ [
      # Advanced monitor management
      inputs.hyprdynamicmonitors.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";

    # Load the configuration fragments after Home Manager's generated Lua
    # prelude. A non-empty configuration also satisfies its systemd check.
    extraConfig = ''
      local configHome = os.getenv("XDG_CONFIG_HOME")
      if configHome == nil or configHome == "" then
        configHome = os.getenv("HOME") .. "/.config"
      end

      local hyprConfig = configHome .. "/hypr/"
      dofile(hyprConfig .. "hypr_variables.lua")
      dofile(hyprConfig .. "hypr_monitors.lua")
      dofile(hyprConfig .. "hypr_settings.lua")
      dofile(hyprConfig .. "hypr_windows.lua")
      dofile(hyprConfig .. "hypr_binds.lua")
      dofile(hyprConfig .. "hypr_exec_once.lua")
    '';

    # Packages are manged by the NixOS module
    # in modules/core/wayland.nix
    # https://wiki.hypr.land/Nix/Hyprland-on-Home-Manager/
    package = null;
    portalPackage = null;

    xwayland = {
      enable = true;
    };

    systemd = {
      enable = true;
      # Fixes missing envs for apps run from hyprland
      variables = [ "--all" ];
    };
  };

  # Use an embedded pointer by default for portal screencasts. Browsers such as
  # Google Meet then include it even when they do not request a cursor mode.
  xdg.configFile."hypr/xdph.conf".text = ''
    screencopy {
      cursor_mode = 2
    }
  '';
}
