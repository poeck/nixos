{ ... }:
{
  imports = [
    ./password/op.nix
    ./nixpkgs.nix
    ./bootloader.nix
    ./hardware.nix
    ./xserver.nix
    ./network.nix
    ./nh.nix
    ./audio.nix
    ./program.nix
    ./security.nix
    ./services.nix
    ./system.nix
    ./user.nix
    ./wayland.nix
    ./keyd.nix
    ./printing.nix
    ./podman.nix
    ./ld.nix
    ./steam.nix
    ./appimage.nix
  ];
}
