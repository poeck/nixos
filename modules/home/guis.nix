{ pkgs, inputs, ... }:
let
  makeSandbox = import ./lib/make-sandbox.nix { inherit pkgs inputs; };
  makeElectronSandbox = import ./lib/make-electron-sandbox.nix { inherit pkgs inputs; };
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

  # Hyprland is not auto-detected as a Secret Service desktop by Electron.
  # Select the running oo7 keyring so T3 Code can encrypt saved connections.
  xdg.desktopEntries.t3code-nightly = {
    name = "T3 Code Nightly";
    comment = "Control coding agents";
    exec = "t3code-nightly --password-store=gnome-libsecret %U";
    icon = "t3code-nightly";
    terminal = false;
    categories = [ "Development" ];
  };

  home.packages = with pkgs; [
    blinkdisk
    claude-desktop
    inputs.gather-linux.packages.${pkgs.stdenv.hostPlatform.system}.default
    # Change nightly to stable to follow stable releases.
    inputs.t3code.packages.${pkgs.stdenv.hostPlatform.system}.nightly
    keeper-password-manager
    pear-desktop
    proton-authenticator
    slack
    expresslrs-configurator
    (pkgs.symlinkJoin {
      name = "handy";
      paths = [
        pkgs.handy
        pkgs.wtype
        pkgs.dotool
      ];
    })
    (makeElectronSandbox {
      package = pkgs.affine;
      binPath = "bin/affine";
      permissions = [
        "network"
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
