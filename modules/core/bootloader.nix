{ pkgs, inputs, ... }:
{
  imports = [ inputs.minegrub.nixosModules.default inputs.mineplymouth.nixosModules.default ];

  boot = {
    loader = {
      grub = {
        # Use grub as the bootloader
        enable = true;
        # Enables efi support
        efiSupport = true;
        # Switch to UEFI mode
        device = "nodev";
        # Auto scan for windows
        useOSProber = true;
        # Theme
        minegrub-theme = {
          enable = true;
          splash = "I use NixOS, btw!";
          background = "background_options/1.8  - [Classic Minecraft].png";
          boot-options-count = 10;
        };
      };
      # Timeout after 30s
      timeout = 30;
      # Allow writing boot entries
      efi.canTouchEfiVariables = true;
    };

    # Show GUI while booting
    plymouth = {
      enable = true;
      theme = "mc";
      extraConfig = "ShowDelay=0";
      themePackages = [
        inputs.mineplymouth.packages.${pkgs.system}.default
      ];
    };

    kernelParams = [ 
      # Don't show any logs at boot
      "quiet"
      # Only show errors
      "loglevel=3"
      # Allow plymouth to use simpledrm
      "plymouth.use-simpledrm"
    ];

    # Supress kernel logs at boot
    consoleLogLevel = 0;

    initrd = {
      verbose = false;
      # Experimental feature that makes initrd use
      # systemd for PID to start plymouth earlier
      #
      # This is required to
      # 1. Enter the luks passphrase in plymouth instead of tty
      # 2. Unlock the gnome keyring via the luks passphrase
      systemd.enable = true;
    };

    # Use the latest kernel
    kernelPackages = pkgs.linuxPackages_latest;

    # Enable support for windows
    supportedFilesystems = [ "ntfs" ];
  };
}
