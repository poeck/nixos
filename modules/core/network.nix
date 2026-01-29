{ pkgs, host, ... }:
{
  networking = {
    # Set's the device hostname
    hostName = "${host}";
    # Essential for networking
    networkmanager = {
      enable = true;
      dns = "none";
      plugins = with pkgs; [
        networkmanager-openvpn
      ];
    };
    nameservers = [
      # Cloudflare
      "1.1.1.1"
      "1.1.0.0"
      # Google
      "8.8.8.8"
      "8.8.4.4"
    ];
    # These options are unnecessary when managing DNS ourselves
    useDHCP = false;
    dhcpcd.enable = false;
    extraHosts =
    ''
      10.20.50.4 otark-db.mysql.database.azure.com
    '';
  };

  # GUI & tray for wifi
  environment.systemPackages = with pkgs; [ networkmanagerapplet ];
}
