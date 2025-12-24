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
    ];

    # Supress kernel logs at boot
    consoleLogLevel = 0;

    initrd = {
      verbose = false;
      # Load AMD driver to show plymouth quicker (?)
      kernelModules = [ "amdgpu" ];
      # Experimental feature that makes initrd use
      # systemd for PID 1to start plymouth earlier
      systemd.enable = true;
    };

    # Use the latest kernel
    kernelPackages = pkgs.linuxPackages_latest;

    # Enable support for windows
    supportedFilesystems = [ "ntfs" ];
  };
}
