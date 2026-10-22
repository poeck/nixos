{ inputs, host, ... }:
{
  imports = [ inputs.island.homeManagerModules.default ];

  services.island = {
    enable = true;
    preview = false;
    settings = {
      monitor = if host == "atlas" then "AOC Q27G4ZR" else "Sharp Corporation LQ160R1JW02";
      notifications = true;
      polkit = true;
      pamService = "swaylock";
      terminal = [ "alacritty" "-e" ];
      # Automatically detect the laptop backlight; other features are on by default.
      backlightDevice = "";
      reducedMotion = false;
    };
  };
}
