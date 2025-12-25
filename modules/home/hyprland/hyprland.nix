{ pkgs, inputs, ... }:
{
  home.packages = with pkgs; [
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
  ] ++ [
    # Advanced monitor management
    inputs.hyprdynamicmonitors.packages.${pkgs.system}.default
  ];
  
  wayland.windowManager.hyprland = {
    enable = true;

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
      variables = ["--all"];
    };
  };
}
