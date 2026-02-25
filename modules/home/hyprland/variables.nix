{ ... }:
{
  home.sessionVariables = {
    # Hint electron apps to use wayland
    NIXOS_OZONE_WL = "1";
    __GL_GSYNC_ALLOWED = 0;
    __GL_VRR_ALLOWED = 0;
    SSH_AUTH_SOCK = "/run/user/1000/ssh-agent";
    DISABLE_QT5_COMPAT = 0;
    GDK_BACKEND = "wayland";
    ANKI_WAYLAND = 1;
    WLR_DRM_NO_ATOMIC = 1;
    QT_AUTO_SCREEN_SCALE_FACTOR = 1;
    QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;
    QT_QPA_PLATFORM = "wayland";
    QT_QPA_PLATFORMTHEME = "qt5ct";
    MOZ_ENABLE_WAYLAND = 1;
    WLR_BACKEND = "vulkan";
    WLR_RENDERER = "vulkan";
    WLR_NO_HARDWARE_CURSORS = 1;
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Hyprland";
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";
    GTK_THEME = "Adwaita:dark";
    GRIMBLAST_HIDE_CURSOR = 0;
    # Fixes issues with wrangler
    SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
  };

  wayland.windowManager.hyprland = {
    extraConfig = ''
      # Run hyprland on the amd gpu
      env = AQ_DRM_DEVICES, /dev/dri/amd-gpu
      # Fix for electron apps
      env = ELECTRON_OZONE_PLATFORM_HINT,auto
      # Fix for programs like steam
      env = QT_QPA_PLATFORM,wayland

      # Load monitors from hyprdynamicmonitors
      source = ~/.config/hypr/monitors.conf
    '';
  };
}
