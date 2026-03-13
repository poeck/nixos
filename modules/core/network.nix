{ pkgs, host, ... }:
{

  services.resolved = {
    enable = true;
    settings.Resolve = {
      # Use Cloudflare and Google as upstream DNS
      FallbackDNS = [
        "1.1.1.1"
        "1.0.0.1"
        "8.8.8.8"
        "8.8.4.4"
      ];
      # Cache DNS lookups locally for faster repeated queries
      DNSSEC = "no";
    };
  };

  boot.kernel.sysctl = {
    # Use Google's BBR congestion control for faster, more stable connections
    "net.core.default_qdisc" = "fq_codel";
    "net.ipv4.tcp_congestion_control" = "bbr";
  };

  networking = {
    # Set's the device hostname
    hostName = "${host}";
    # Essential for networking
    networkmanager = {
      enable = true;
      dns = "systemd-resolved";
      wifi.powersave = false;
      settings.connectivity = {
        enabled = true;
        uri = "http://nmcheck.gnome.org/check_network_status.txt";
        interval = 300;
      };
    };
    extraHosts = ''
      10.20.50.4 otark-db.mysql.database.azure.com
    '';
  };

  # services.openvpn.servers = {
  #   otark = {
  #     # Use 'config' to point to your existing .ovpn file
  #     config = "config /root/vpn/otark.ovpn";

  #     autoStart = false;
  #     updateResolvConf = false;
  #   };
  # };

  environment.systemPackages = with pkgs; [
    # GUI & tray for wifi
    networkmanagerapplet
    # Dig requests
    dig
  ];
}
