{ pkgs, inputs, ... }:
let
  mkNixPak = inputs.nixpak.lib.nixpak {
    inherit (pkgs) lib;
    inherit pkgs;
  };

  sandboxed-affine = mkNixPak {
    config =
      { sloth, ... }:
      {
        app.package = pkgs.affine;
        flatpak.appId = "pro.affine.app";

        gpu.enable = true;
        fonts.enable = true;
        locale.enable = true;
        etc.sslCertificates.enable = true;

        dbus.enable = true;
        dbus.policies = {
          "org.freedesktop.Notifications" = "talk";
          "org.freedesktop.portal.*" = "talk";
          "org.a11y.Bus" = "talk";
          "ca.desrt.dconf" = "talk";
        };

        bubblewrap = {
          network = true;

          sockets.wayland = true;
          sockets.pipewire = true;

          bind.rw = [
            [
              (sloth.concat' sloth.homeDir "/.local/state/nixpak/affine/config")
              sloth.xdgConfigHome
            ]
            [
              (sloth.concat' sloth.homeDir "/.local/state/nixpak/affine/cache")
              sloth.xdgCacheHome
            ]
            [
              (sloth.concat' sloth.homeDir "/.local/state/nixpak/affine/data")
              sloth.xdgDataHome
            ]
          ];
        };
      };
  };
in
{
  home.packages = with pkgs; [
    pavucontrol
    blinkdisk
    geary
    inputs.handy.packages.${pkgs.stdenv.hostPlatform.system}.default
    sandboxed-affine.config.env
    proton-authenticator
  ];

  home.file = {
    ".config/electron-flags.conf" = {
      # Force electron apps to use wayland
      text = ''
        --enable-features=UseOzonePlatform
        --ozone-platform=wayland
      '';
    };
  };
}
