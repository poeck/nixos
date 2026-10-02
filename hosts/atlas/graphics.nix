{ config, ... }:
{
  # RTX 3060 Ti drives the desktop directly; no laptop PRIME bus IDs/offload.
  services.xserver.videoDrivers = [ "nvidia" ];
  # Have the GPU ready before Plymouth hands over to the autologin session.
  boot.initrd.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];
  hardware.nvidia = {
    modesetting.enable = true;
    # Preserve video memory across suspend/resume with NVIDIA's sleep services.
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    open = true;
    nvidiaSettings = false;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
}
