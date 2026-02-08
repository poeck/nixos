{
  pkgs,
  ...
}:
{
  blinkdisk = pkgs.callPackage ./blinkdisk.nix { };
  wtp = pkgs.callPackage ./wtp.nix { };
}
