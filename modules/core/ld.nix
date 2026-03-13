{ options, pkgs, ... }:
{
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries =
    options.programs.nix-ld.libraries.default
    ++ (with pkgs; [
      # Dependencies for electron apps
      cups.lib
      dbus
      glib
      nss
      nspr
      atk
      at-spi2-atk
      libdrm
      expat
      libgbm
      gtk3
      pango
      cairo
      alsa-lib
      systemd
      libusb1
      libxkbcommon
      libX11
      libXcomposite
      libXdamage
      libXext
      libXfixes
      libXrandr
      libXrender
      libXtst
      libXi
      libxcb
      mesa
    ]);
}
