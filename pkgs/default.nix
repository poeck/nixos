{
  inputs,
  pkgs,
  ...
}:
{
  blinkdisk = pkgs.callPackage ./blinkdisk.nix { };
  helium = pkgs.callPackage ./helium.nix { };
}
