{ pkgs, host, ... }:
{
  services = {
    # Virtual filesystems for NASj
    gvfs.enable = true;
    # Discard unused blocks from fs
    fstrim.enable = true;

    gnome = {
      at-spi2-core.enable = true;
      # File indexing?
      tinysparql.enable = true;
    };

    # Needed for GNOME services outside of GNOME Desktop
    dbus = {
      enable = true;
      packages = with pkgs; [
        gcr_3
        gnome-settings-daemon
      ];
    };

    logind = {
      settings = {
        Login = {
          HandleLidSwitch = if host == "zephyrus" then "suspend-then-hibernate" else "suspend";
          HandlePowerKey = "poweroff";
          HandlePowerKeyLongPress = "poweroff";
        };
      };
    };

    # Linux essential for managing storage devices
    udisks2.enable = true;
    # Smart-card service used by WebAuthn/security-key integrations.
    pcscd.enable = true;
  };

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = false;
  };
}
