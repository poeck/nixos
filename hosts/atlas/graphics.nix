{ config, pkgs, ... }:
{
  # Hyprland 0.57 sends empty HDR metadata on the first SDR frame, which
  # causes NVIDIA outputs to enter an EINVAL modeset loop. Keep the earlier
  # behavior until the upstream release fixes this regression (#16764).
  programs.hyprland.package =
    if pkgs.hyprland.version == "0.57.0" then
      pkgs.hyprland.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          substituteInPlace src/render/Renderer.cpp \
            --replace-fail 'const bool INITIAL_SDR          = !pMonitor->m_needsHDRupdate && !wantHDR;' '/* Initial SDR metadata is intentionally left unchanged on NVIDIA. */' \
            --replace-fail 'HDR_CHANGED || INITIAL_SDR ||' 'HDR_CHANGED ||'
        '';
      })
    else
      pkgs.hyprland;

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
