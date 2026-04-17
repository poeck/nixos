{
  pkgs,
  ...
}:
{
  blinkdisk = pkgs.callPackage ./blinkdisk.nix { };
  sandbox = pkgs.callPackage ./sandbox.nix { };
}
