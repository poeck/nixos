{
  config,
  lib,
  pkgs,
  ...
}:
let
  secretDirectory = "/etc/secrets/initrd/atlas";
  wifiConfig = "/etc/wpa_supplicant/atlas.conf";
  prepare = pkgs.writeShellApplication {
    name = "atlas-initrd-prepare";
    runtimeInputs = [
      pkgs.python3
      pkgs.networkmanager
      pkgs.openssh
    ];
    text = ''
      exec python3 ${../../scripts/atlas-initrd-prepare.py} "$@"
    '';
  };
in
{
  assertions = [
    {
      assertion = config.boot.initrd.systemd.enable && config.boot.loader.supportsInitrdSecrets;
      message = "Atlas remote unlock requires systemd initrd and bootloader-side secret injection.";
    }
  ];

  environment.systemPackages = [ prepare ];
  # Bootstrap the root-only files before the first bootloader installation.
  system.build.atlasInitrdPrepare = prepare;

  boot.initrd = {
    # Intel AX201: include the driver dependencies and firmware before / opens.
    availableKernelModules = [
      "iwlwifi"
      "iwlmvm"
      "ccm"
      "ctr"
    ];
    extraFirmwarePaths = [ "iwlwifi-so-a0-hr-b0-89.ucode" ];

    # String paths are intentionally read only by the bootloader installer.
    # Neither the WLAN PSK nor the private host key enters the Nix store.
    secrets.${wifiConfig} = "${secretDirectory}/wpa_supplicant.conf";
    network.ssh = {
      enable = true;
      port = 2222;
      hostKeys = [ "${secretDirectory}/ssh_host_ed25519_key" ];
      authorizedKeyFiles = [ ../../keys/paul.pub ];
      extraConfig = ''
        AddressFamily inet
        PermitRootLogin prohibit-password
        AuthenticationMethods publickey
        AllowUsers root
        AllowAgentForwarding no
        AllowTcpForwarding no
        X11Forwarding no
        PermitTunnel no
        PermitUserRC no
        ForceCommand /bin/systemd-tty-ask-password-agent --watch
      '';
    };

    systemd = {
      # Keep a real shell for sshd's forced-command execution. The only remotely
      # accessible command is the password agent; Plymouth remains independent.
      users.root.shell = "/bin/bash";
      storePaths = [ "${pkgs.wpa_supplicant}/sbin/wpa_supplicant" ];
      extraBin.systemd-tty-ask-password-agent = "${config.boot.initrd.systemd.package}/bin/systemd-tty-ask-password-agent";

      network = {
        enable = true;
        networks."10-atlas-wifi" = {
          matchConfig.Name = "wlo1";
          networkConfig = {
            DHCP = "ipv4";
            IPv6AcceptRA = false;
            LinkLocalAddressing = "no";
          };
          # Reuse the FRITZ!Box reservation for 00:91:9e:c0:c5:51 (.116).
          dhcpV4Config.ClientIdentifier = "mac";
          # Network availability must not hold up a local Plymouth unlock.
          linkConfig.RequiredForOnline = false;
        };
      };

      services.atlas-initrd-wifi = {
        description = "Atlas Wi-Fi for remote LUKS unlock";
        wantedBy = [ "initrd.target" ];
        requires = [ "sys-subsystem-net-devices-wlo1.device" ];
        after = [
          "sys-subsystem-net-devices-wlo1.device"
          "initrd-nixos-copy-secrets.service"
        ];
        before = [
          "network.target"
          "shutdown.target"
        ];
        conflicts = [ "shutdown.target" ];
        unitConfig.DefaultDependencies = false;
        serviceConfig = {
          Type = "simple";
          RuntimeDirectory = "wpa_supplicant";
          RuntimeDirectoryMode = "0700";
          ExecStart = "${pkgs.wpa_supplicant}/sbin/wpa_supplicant -Dnl80211 -iwlo1 -c${wifiConfig}";
          Restart = "on-failure";
          RestartSec = 3;
        };
      };
    };
  };
}
