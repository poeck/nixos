{
  inputs,
  pkgs,
  ...
}:
{
  helium = pkgs.callPackage ./helium { inherit inputs; };
}
