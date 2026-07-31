{ pkgs, host, ... }:
{
  services.tailscale.enable = true;

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
      plugins = [ pkgs.networkmanager-openvpn ];
      settings.connectivity = {
        enabled = true;
        uri = "http://nmcheck.gnome.org/check_network_status.txt";
        interval = 300;
      };
    };
  };

  # Keep the WireGuard credentials in a root-only runtime file rather than in
  # this repository (or the world-readable Nix store). Bring the tunnel up with
  # `sudo systemctl start wg-quick-otark`.
  networking.wg-quick.interfaces.otark = {
    autostart = false;
    configFile = "/root/vpn/otark-wireguard.conf";
  };

  # systemd-resolved normally reserves `.local` for mDNS. Route Otark's
  # private zone explicitly to the DNS server configured by wg-quick.
  systemd.services.wg-quick-otark.postStart = ''
    ${pkgs.systemd}/bin/resolvectl domain otark '~.' '~otark.local'
  '';

  environment.systemPackages = with pkgs; [
    # GUI & tray for wifi
    networkmanagerapplet
    # Dig requests
    dig
  ];
}
