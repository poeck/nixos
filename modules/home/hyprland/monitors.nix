{ pkgs, ... }:
{
  wayland.windowManager.hyprland = {
    settings.monitor = [
      # Left monitor
      "desc:Shenzhen KTC Technology Group PMO G241-FFK, 1920x1080@75, -1920x0, 1, bitdepth, 10"
      # Middle monitor
      "desc:Philips Consumer Electronics Company PHL 246E9Q 0x000036F7, 1920x1080@75, 0x0, 1, bitdepth, 10"
      # Internal laptop monitor
      "desc:Sharp Corporation LQ160R1JW02, 2560x1600@244, 1920x0, 1.6, bitdepth, 10"
    ];
  };

  home.packages = with pkgs; [ nwg-displays ];
}
