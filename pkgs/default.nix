{
  pkgs,
  ...
}:
{
  blinkdisk = pkgs.callPackage ./blinkdisk.nix { };
  wtp = pkgs.callPackage ./wtp.nix { };
  keeper = pkgs.callPackage ./keeper.nix { };
  sandbox = pkgs.callPackage ./sandbox.nix { };
}
