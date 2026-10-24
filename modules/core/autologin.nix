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

  # agetty's autologin skips PAM authentication. Inject the cached Plymouth /
  # LUKS password during the session phase, before GNOME Keyring consumes it.
  # Keep the password in the kernel keyring; never put it in the Nix store.
  # Extend the NixOS template itself. An instance drop-in named overrides.conf
  # masks the template's overrides.conf, losing its Nix store ExecStart and
  # autologin setup and falling back to the nonexistent /usr/bin/agetty.
  systemd.services."getty@".serviceConfig.KeyringMode = "inherit";
  security.pam.services.login.rules.session = {
    fde_boot_pw_guard = {
      order = config.security.pam.services.login.rules.session.gnome_keyring.order - 20;
      control = "[success=ok default=1]";
      modulePath = "${pkgs.pam}/lib/security/pam_succeed_if.so";
      args = [
        "quiet"
        "user"
        "="
        username
        "tty"
        "=~"
        "*tty1"
      ];
    };
    fde_boot_pw = {
      order = config.security.pam.services.login.rules.session.gnome_keyring.order - 10;
      control = "optional";
      modulePath = "${pkgs.pam_fde_boot_pw}/lib/security/pam_fde_boot_pw.so";
      args = [ "inject_for=gkr" ];
    };
  };

  home-manager.users.${username}.programs.zsh.profileExtra = ''
    if [[ -z "$DISPLAY" && -z "$WAYLAND_DISPLAY" && "$(tty)" == "/dev/tty1" ]]; then
      # Use Hyprland's launcher and keep startup output off the boot console.
      exec ${lib.getExe' pkgs.systemd "systemd-cat"} --identifier=hyprland \
        ${lib.getExe' config.programs.hyprland.package "start-hyprland"}
    fi
  '';
}
