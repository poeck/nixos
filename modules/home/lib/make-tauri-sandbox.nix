{ pkgs, inputs }:
let
  inherit (pkgs) lib;
  makeSandbox = import ./make-sandbox.nix { inherit pkgs inputs; };
in
{
  permissions ? [ ],
  ...
}@args:
(makeSandbox (
  args
  // {
    permissions = lib.unique (
      permissions
      ++ [
        "gui"
      ]
    );
  }
)).config.env
