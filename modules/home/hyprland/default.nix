{ ... }:
{
  imports = [
    ./hyprland.nix
    ./exec-once.nix
    ./settings.nix
    ./binds.nix
    ./windows.nix
    ./hypridle.nix
    ./activity-guard.nix
    ./variables.nix
    ./monitors
    ./remote-desktop.nix
  ];
}
