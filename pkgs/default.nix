{
  pkgs,
  ...
}:
{
  acli = pkgs.callPackage ./acli.nix { };
  blinkdisk = pkgs.callPackage ./blinkdisk.nix { };
  keeper-password-manager = pkgs.callPackage ./keeper-password-manager.nix { };
  sandbox = pkgs.callPackage ./sandbox.nix { };
}
