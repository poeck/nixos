# Atlas: ASUS PRIME Z690-P WIFI D4, Intel i7-12700K, NVIDIA RTX 3060 Ti.
# Storage is the encrypted SSD moved from Zephyrus, so its UUIDs are unchanged.
# Verify/refine this file with nixos-generate-config on Atlas under NixOS.
{ config, lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usb_storage"
    "usbhid"
    "sd_mod"
  ];
  boot.kernelModules = [ "kvm-intel" ];

  fileSystems."/" = {
    device = "/dev/mapper/luks-6703cce4-a14d-477a-8388-c62b4fb61759";
    fsType = "ext4";
  };

  boot.initrd.luks.devices."luks-6703cce4-a14d-477a-8388-c62b4fb61759" = {
    device = "/dev/disk/by-uuid/6703cce4-a14d-477a-8388-c62b4fb61759";
    crypttabExtraOpts = [ "tries=10" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/A291-69A9";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 32 * 1024;
    }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
