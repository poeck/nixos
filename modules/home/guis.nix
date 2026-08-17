{ pkgs, inputs, ... }:
let
  makeSandbox = import ./lib/make-sandbox.nix { inherit pkgs inputs; };
  makeElectronSandbox = import ./lib/make-electron-sandbox.nix { inherit pkgs inputs; };
  makeTauriSandbox = import ./lib/make-tauri-sandbox.nix { inherit pkgs inputs; };
in
{
  # The bundled Electron launcher can fall back to XWayland, which makes the
  # UI blurry on fractionally scaled displays. A user desktop entry with the
  # same ID takes precedence over the system entry and forces native Wayland.
  xdg.desktopEntries.chatgpt = {
    name = "ChatGPT";
    comment = "ChatGPT by OpenAI";
    genericName = "AI assistant";
    exec = "chatgpt --ozone-platform=wayland %U";
    icon = "chatgpt";
    terminal = false;
    categories = [
      "Utility"
      "Development"
    ];
    mimeType = [
      "x-scheme-handler/codex"
      "text/csv"
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      "application/vnd.openxmlformats-officedocument.presentationml.presentation"
      "text/tab-separated-values"
      "application/vnd.ms-excel"
      "application/vnd.ms-excel.sheet.macroEnabled.12"
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    ];
    startupNotify = true;
  };

  home.packages = with pkgs; [
    blinkdisk
    claude-desktop
    inputs.gather-linux.packages.${pkgs.stdenv.hostPlatform.system}.default
    keeper-password-manager
    pear-desktop
    slack
    expresslrs-configurator
    (makeTauriSandbox {
      name = "handy";
      binPath = "bin/handy";
      package = pkgs.symlinkJoin {
        name = "handy-with-typing";
        paths = [
          pkgs.handy
          pkgs.wtype
          pkgs.dotool
        ];
      };
      permissions = [
        "network" # required to download models
        "audio"
      ];
      extraConfig = _: {
        bubblewrap.bind = {
          # Handy initializes Enigo through XWayland before its direct-input
          # path can hand text to wtype. Without this socket, Enigo remains
          # uninitialized and Handy aborts every paste operation.
          ro = [ "/tmp/.X11-unix" ];
          dev = [ "/dev/uinput" ];
        };
      };
    })
    (makeElectronSandbox {
      package = pkgs.affine;
      binPath = "bin/affine";
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
      binPath = "bin/geary";
      permissions = [
        "gui"
        "network"
        "keyring"
        "notifications"
      ];
      extraConfig =
        { sloth, ... }:
        {
          dbus.policies = {
            "org.gnome.Geary" = "own";
            "org.gnome.OnlineAccounts" = "talk";
            "org.gnome.evolution.dataserver.Sources5" = "talk";
            "org.gnome.evolution.dataserver.AddressBook10" = "talk";
            "org.gnome.evolution.dataserver.Calendar8" = "talk";
          };
          bubblewrap.bind.rw = [
            [
              sloth.xdgDownloadDir
              sloth.xdgDownloadDir
            ]
          ];
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
  ];
}
