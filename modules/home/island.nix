{ inputs, host, pkgs, ... }:
{
  imports = [ inputs.island.homeManagerModules.default ];

  services.island = {
    enable = true;
    # Carry the launcher fix until the Island input includes it upstream.
    package = inputs.island.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
      patches = (old.patches or []) ++ [ ./lib/island-launch-environment.patch ];
    });
    preview = false;
    settings = {
      monitor = if host == "atlas" then "AOC Q27G4ZR" else "Sharp Corporation LQ160R1JW02";
      notifications = true;
      polkit = true;
      askpass = true;
      pamService = "swaylock";
      terminal = [ "alacritty" "-e" ];
      # Automatically detect the laptop backlight; other features are on by default.
      backlightDevice = "";
      reducedMotion = false;
    };
  };
}
