{
  inputs,
  pkgs,
  ...
}:
{
  blinkdisk = pkgs.callPackage ./blinkdisk.nix { };
}
