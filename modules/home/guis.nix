{ config, pkgs, inputs, ... }:
{
  # The bundled Electron launcher can fall back to XWayland, which makes the
  # UI blurry on fractionally scaled displays. A user desktop entry with the
  # same ID takes precedence over the system entry and forces native Wayland.
  xdg.desktopEntries.chatgpt = {
    name = "ChatGPT";
    comment = "ChatGPT by OpenAI";
    genericName = "AI assistant";
    exec = "chatgpt --ozone-platform=wayland --password-store=gnome-libsecret %U";
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

  # A pre-existing local desktop entry takes precedence over desktop entries in
  # the Nix profile. Own that local entry so the app never shares the service's
  # ~/.t3 directory. Hyprland also needs an explicit Secret Service backend.
  xdg.dataFile."applications/t3code-nightly.desktop" = {
    force = true;
    text = ''
      [Desktop Entry]
      Type=Application
      Version=1.5
      Name=T3 Code Nightly
      Comment=Control coding agents
      Exec=${pkgs.coreutils}/bin/env T3CODE_HOME=${config.home.homeDirectory}/.t3-desktop t3code-nightly --password-store=gnome-libsecret %U
      Icon=t3code-nightly
      Terminal=false
      Categories=Development;
    '';
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
