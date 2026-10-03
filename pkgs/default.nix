{
  pkgs,
  ...
}:
{
  acli = pkgs.callPackage ./acli.nix { };
  blinkdisk = pkgs.callPackage ./blinkdisk.nix { };
  keeper-password-manager = pkgs.callPackage ./keeper-password-manager.nix { };
  sandbox = pkgs.callPackage ./sandbox.nix { };
  t3-cli = pkgs.callPackage ./t3-cli.nix { };
}
