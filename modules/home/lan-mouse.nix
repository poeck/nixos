{
  config,
  host,
  lib,
  pkgs,
  ...
}:
let
  isSender = host == "atlas";
  configPath = "${config.xdg.configHome}/lan-mouse/config.toml";
  defaults = (pkgs.formats.toml { }).generate "lan-mouse-desk.toml" {
    capture_backend = "layer-shell";
    emulation_backend = "wlroots";
    port = 4242;
    cert_path = "${config.xdg.configHome}/lan-mouse/lan-mouse.pem";
    release_bind = [
      "KeyLeftCtrl"
      "KeyLeftAlt"
      "KeyLeftShift"
      "KeyLeftMeta"
    ];
    # Zephyrus only receives: its own keyboard and trackpad stay local.
    clients = lib.optionals isSender [
      {
        hostname = "zephyrus.alpines-pauling.ts.net";
        position = "left";
        activate_on_startup = true;
      }
    ];
  };
  prepareConfig = pkgs.writeShellApplication {
    name = "prepare-lan-mouse-desk";
    runtimeInputs = [ pkgs.python3 ];
    text = ''
      python3 ${../../scripts/lan-mouse-prepare.py} ${defaults} ${lib.escapeShellArg configPath}
    '';
  };
  waitForDaemon = pkgs.writeShellApplication {
    name = "wait-for-lan-mouse";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.lan-mouse
    ];
    text = ''
      for attempt in {1..30}; do
        if lan-mouse --config ${lib.escapeShellArg configPath} cli list >/dev/null 2>&1; then
          exit 0
        fi
        sleep 0.1
      done
      echo "Lan Mouse's control socket did not become ready after $attempt attempts." >&2
      exit 1
    '';
  };
  deskControl = pkgs.writeShellApplication {
    name = "lan-mouse-desk";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.lan-mouse
      pkgs.libnotify
      pkgs.systemd
      pkgs.util-linux
    ];
    text = ''
      export LAN_MOUSE_HOST=${lib.escapeShellArg host}
      export LAN_MOUSE_CONFIG=${lib.escapeShellArg configPath}
      ${builtins.readFile ../../scripts/lan-mouse-desk.sh}
    '';
  };
in
{
  home.packages = [
    pkgs.lan-mouse
    deskControl
  ];

  systemd.user.services.lan-mouse = {
    Unit = {
      Description = if isSender then "Manual Lan Mouse sharing" else "Lan Mouse receiver";
      # The receiver is wanted by hyprland-session.target. Ordering it after
      # that same target would create a cycle during session startup.
      Requisite = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      PartOf = [ "hyprland-session.target" ];
      ConditionEnvironment = "WAYLAND_DISPLAY";
    };
    Service = {
      Type = "exec";
      ExecStartPre = lib.getExe prepareConfig;
      ExecStart = "${lib.getExe pkgs.lan-mouse} --config ${lib.escapeShellArg configPath} daemon";
      ExecStartPost = lib.getExe waitForDaemon;
      Restart = if isSender then "no" else "on-failure";
      RestartSec = 3;
      TimeoutStartSec = 20;
      TimeoutStopSec = 5;
      # Lan Mouse handles SIGINT by releasing input and closing connections.
      KillSignal = "SIGINT";
      UMask = "0077";
    };
    Install.WantedBy = lib.optionals (!isSender) [ "hyprland-session.target" ];
  };

  # Opening the GUI must use the managed service, so stopping that service
  # always stops sharing even while the pairing window is open.
  xdg.desktopEntries."de.feschber.LanMouse" = {
    name = "Lan Mouse";
    comment = "Pair devices and inspect keyboard/mouse sharing";
    exec = "${lib.getExe deskControl} gui";
    icon = "de.feschber.LanMouse";
    categories = [ "Utility" ];
    terminal = false;
  };
  xdg.desktopEntries.lan-mouse-desk = {
    name = if isSender then "Lan Mouse: Toggle sharing" else "Lan Mouse: Toggle receiver";
    exec = lib.getExe deskControl;
    icon = "de.feschber.LanMouse";
    categories = [ "Utility" ];
    terminal = false;
  };
}
