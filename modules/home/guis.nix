{ pkgs, inputs, ... }:
let
  makeSandbox = import ./lib/make-sandbox.nix { inherit pkgs inputs; };
  makeElectronSandbox = import ./lib/make-electron-sandbox.nix { inherit pkgs inputs; };
  makeTauriSandbox = import ./lib/make-tauri-sandbox.nix { inherit pkgs inputs; };
in
{
  home.packages = with pkgs; [
    blinkdisk
    (makeTauriSandbox {
      name = "handy";
      package = pkgs.symlinkJoin {
        name = "handy-with-typing";
        paths = [
          inputs.handy.packages.${pkgs.stdenv.hostPlatform.system}.default
          pkgs.wtype
          pkgs.dotool
        ];
      };
      permissions = [
        "network" # required to download models
        "audio"
      ];
      extraConfig = _: {
        bubblewrap.bind.dev = [ "/dev/uinput" ];
      };
    })
    (makeElectronSandbox {
      package = pkgs.affine;
      permissions = [
        "network"
      ];
    })
    (makeTauriSandbox {
      package = pkgs.proton-authenticator;
      permissions = [
        "network"
        "keyring"
      ];
    })
    (makeSandbox {
      package = pkgs.geary;
      permissions = [
        "gui"
        "network"
        "keyring"
        "notifications"
      ];
      extraConfig = _: {
        dbus.policies = {
          "org.gnome.Geary" = "own";
          "org.gnome.OnlineAccounts" = "talk";
          "org.gnome.evolution.dataserver.Sources5" = "talk";
          "org.gnome.evolution.dataserver.AddressBook10" = "talk";
          "org.gnome.evolution.dataserver.Calendar8" = "talk";
        };
      };
    }).config.env
    (makeSandbox {
      package = pkgs.pavucontrol;
      permissions = [
        "gui"
        "audio"
      ];
      extraConfig = _: {
        dbus.policies = {
          "org.pulseaudio.pavucontrol" = "own";
        };
      };
    }).config.env
    (makeSandbox {
      package = pkgs.vicinae;
      permissions = [
        "gui"
      ];
    }).config.env
  ];
}
