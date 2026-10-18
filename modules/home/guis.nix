{ config, pkgs, inputs, ... }:
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
  # Select GNOME Keyring so T3 Code can encrypt saved connections.
  # Keep desktop client settings separate from the background server's ~/.t3.
  xdg.desktopEntries.t3code-nightly = {
    name = "T3 Code Nightly";
    comment = "Control coding agents";
    exec = "${pkgs.coreutils}/bin/env T3CODE_HOME=${config.home.homeDirectory}/.t3-desktop t3code-nightly --password-store=gnome-libsecret %U";
    icon = "t3code-nightly";
    terminal = false;
    categories = [ "Development" ];
  };

  home.packages = with pkgs; [
    blinkdisk
    claude-desktop
    discord
    inputs.gather-linux.packages.${pkgs.stdenv.hostPlatform.system}.default
    # Change nightly to stable to follow stable releases.
    inputs.t3code.packages.${pkgs.stdenv.hostPlatform.system}.nightly
    keeper-password-manager
    pear-desktop
    proton-authenticator
    slack
    expresslrs-configurator
    affine
    pavucontrol
    (pkgs.symlinkJoin {
      name = "handy";
      paths = [
        pkgs.handy
        pkgs.wtype
        pkgs.dotool
      ];
    })
  ];
}
