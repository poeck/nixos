{ config, ... }:
{
  services.udev.extraRules = ''
    # Symlink the AMD Card (Vendor ID 0x1002)
    SUBSYSTEM=="drm", KERNEL=="card*", ATTRS{vendor}=="0x1002", SYMLINK+="dri/amd-gpu"

    # Symlink the Nvidia Card (Vendor ID 0x10de)
    SUBSYSTEM=="drm", KERNEL=="card*", ATTRS{vendor}=="0x10de", SYMLINK+="dri/nvidia-gpu"

    # Prevent small docking station from waking up during suspend
    ACTION=="add" SUBSYSTEM=="pci" ATTR{vendor}=="0x1987" ATTR{device}=="0x5013" ATTR{power/wakeup}="disabled"
  '';

  hardware = {
    graphics = {
      # Enable's OpenGL
      enable = true;
    };
    nvidia = {
      # Modesetting is required for nvidia
      modesetting.enable = true;
      # Experimental, and can cause sleep/suspend to fail.
      powerManagement.enable = false;
      # Turns off GPU when not in use
      powerManagement.finegrained = false;
      # Use the nvidia open source kernel
      open = true;
      #  Enable the nvidia-settings app
      nvidiaSettings = true;
      # Which driver version to use
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      # https://nixos.wiki/wiki/Nvidia
      prime = {
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
        nvidiaBusId = "PCI:100:0:0";
        amdgpuBusId = "PCI:101:0:0";
      };
    };
  };

  hardware.enableRedistributableFirmware = true;
}
