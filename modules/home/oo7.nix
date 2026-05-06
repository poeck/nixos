{ lib, pkgs, ... }:
let
  credentialPath = "$HOME/.local/share/oo7/keyring-encryption-password";
in
{
  home.packages = with pkgs; [
    oo7
    oo7-portal
    oo7-server
  ];

  xdg.configFile."xdg-desktop-portal/hyprland-portals.conf".text = ''
    [preferred]
    default=hyprland;gtk;
    org.freedesktop.impl.portal.Secret=oo7-portal;
  '';

  xdg.dataFile."dbus-1/services/org.freedesktop.impl.portal.desktop.oo7.service".source =
    "${pkgs.oo7-portal}/share/dbus-1/services/org.freedesktop.impl.portal.desktop.oo7.service";
  xdg.dataFile."xdg-desktop-portal/portals/oo7-portal.portal".text = ''
    [portal]
    DBusName=org.freedesktop.impl.portal.desktop.oo7
    Interfaces=org.freedesktop.impl.portal.Secret;
    UseIn=Hyprland;gnome
  '';

  home.activation.createOo7Credential = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "$HOME/.local/share/oo7"
    if [ ! -s "${credentialPath}" ]; then
      run ${pkgs.bash}/bin/bash -c '${pkgs.openssl}/bin/openssl rand -base64 48 | ${pkgs.coreutils}/bin/tr -d "\n" > "$1"' -- "${credentialPath}"
    fi
    run ${pkgs.perl}/bin/perl -0pi -e 's/\n\z//' "${credentialPath}"
    run chmod 700 "$HOME/.local/share/oo7"
    run chmod 600 "${credentialPath}"
  '';

  xdg.dataFile."dbus-1/services/org.freedesktop.secrets.service".source =
    "${pkgs.oo7-server}/share/dbus-1/services/org.freedesktop.secrets.service";

  systemd.user.services."dbus-org.freedesktop.impl.portal.desktop.oo7" = {
    Unit = {
      Description = "Secret portal service (oo7 implementation)";
      Wants = [ "xdg-desktop-portal.service" ];
    };

    Service = {
      Type = "dbus";
      BusName = "org.freedesktop.impl.portal.desktop.oo7";
      ExecStart = "${pkgs.oo7-portal}/libexec/oo7-portal";
    };
  };

  systemd.user.services."dbus-org.freedesktop.secrets" = {
    Unit = {
      Description = "Secret service (oo7 implementation)";
      Documentation = [ "https://linux-credentials.github.io/oo7/oo7/" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.oo7-server}/libexec/oo7-daemon";
      LoadCredential = "oo7.keyring-encryption-password:%h/.local/share/oo7/keyring-encryption-password";
      Restart = "on-failure";
      TimeoutStartSec = "30s";
      TimeoutStopSec = "30s";
      StandardError = "journal";

      NoNewPrivileges = true;
      SupplementaryGroups = "";
      PrivateUsers = true;
      ProtectSystem = "full";
      PrivateTmp = true;
      PrivateDevices = true;
      PrivateNetwork = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      MemoryDenyWriteExecute = true;
      ProtectClock = true;
    };

    Install.WantedBy = [ "default.target" ];
  };
}
