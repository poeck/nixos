{ pkgs, ... }:
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
        gcr
        gnome-settings-daemon
      ];
    };

    logind = {
      settings = {
        Login = {
          HandleLidSwitch = "suspend-then-hibernate";
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
    enableSSHSupport = true;
  };
}
