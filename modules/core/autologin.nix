{ username, ... }:
{
  services.displayManager.enable = false;
  services.xserver.displayManager.lightdm.enable = false;

  # Unlock LUKS, log in once on tty1, and start Hyprland without a login manager.
  services.getty = {
    autologinUser = username;
    autologinOnce = true;
  };

  home-manager.users.${username}.programs.zsh.profileExtra = ''
    if [[ -z "$DISPLAY" && -z "$WAYLAND_DISPLAY" && "$(tty)" == "/dev/tty1" ]]; then
      exec /run/current-system/sw/bin/Hyprland
    fi
  '';
}
