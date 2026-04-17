{ pkgs, inputs }:
let
  inherit (pkgs) lib;
  makeSandbox = import ./make-sandbox.nix { inherit pkgs inputs; };
in
{
  permissions ? [ ],
  extraConfig ? _: { },
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
    extraConfig =
      sandboxArgs:
      lib.recursiveUpdate {
        # Accessibility bus; Electron/Chromium hangs or warns without it.
        dbus.policies."org.a11y.Bus" = "talk";
      } (extraConfig sandboxArgs);
  }
)).config.env
