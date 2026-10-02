{
  config,
  lib,
  pkgs,
  username,
  ...
}:
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
      # Use Hyprland's launcher and keep startup output off the boot console.
      exec ${lib.getExe' pkgs.systemd "systemd-cat"} --identifier=hyprland \
        ${lib.getExe' config.programs.hyprland.package "start-hyprland"}
    fi
  '';
}
