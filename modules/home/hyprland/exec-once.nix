{ ... }:
{
  wayland.windowManager.hyprland.settings.exec-once = [
    # Fix for https://wiki.hypr.land/FAQ/#some-of-my-apps-take-a-really-long-time-to-open
    "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
    # Allows programs to request elevated privileges
    "systemctl --user start hyprpolkitagent"

    # Auto suspend and lock
    "hypridle"
    # Waybar
    "waybar"
    # GUI & tray for wifi
    # Notification center
    "swaync"
    "nm-applet"
    # Wallpaper
    "swaybg -i ${../../../wallpaper.jpg}"
    # Auto mount external drives
    "udiskie --automount --notify --smart-tray &"
    # Cursor
    "hyprctl setcursor Bibata-Modern-Ice 24 &"
    # Clipboard
    "wl-clip-persist --clipboard both &"
    "wl-paste --watch cliphist store &"
    # Launcher
    "vicinae server --replace"
    # Password manager
    "1password --silent"
    # Speech-to-text
    "handy"
    # Best backup tool
    "blinkdisk --hidden"
  ];
}
