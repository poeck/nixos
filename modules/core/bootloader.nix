{ pkgs, inputs, ... }:
{
  imports = [ inputs.minegrub.nixosModules.default ];

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

    # Use the latest kernel
    kernelPackages = pkgs.linuxPackages_latest;

    # Enable support for windows
    supportedFilesystems = [ "ntfs" ];
  };
}
