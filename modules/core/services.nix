{ pkgs, ... }:
{
  services = {
    # Virtual filesystems for NASj
    gvfs.enable = true;
    # Discard unused blocks from fs
    fstrim.enable = true;

    gnome = {
      # File indexing?
      tinysparql.enable = true;
      gnome-keyring.enable = true;
    };

    # Needed for GNOME services outside of GNOME Desktop
    dbus = {
      enable = true;
      packages = with pkgs; [
        gcr
        gnome-settings-daemon
      ];
    };

    logind.settings.Login = {
      # Don’t shutdown when power button is short-pressed
      HandlePowerKey = "ignore";
    };

    # Linux essential for managing storage devices
    udisks2.enable = true;
  };

  # Fix gnome keyring
  # https://discourse.nixos.org/t/login-keyring-did-not-get-unlocked-hyprland/40869/8
  environment.variables.XDG_RUNTIME_DIR = "/run/user/$UID";
}
