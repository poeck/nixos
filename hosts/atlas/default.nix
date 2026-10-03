{ config, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./graphics.nix
    ../../modules/core
    ../../modules/core/media.nix
  ];

  # Desktop: no ASUS laptop daemon, TLP, or laptop-specific ACPI modules.
  powerManagement.enable = true;
  systemd.sleep.settings.Sleep.AllowSuspendThenHibernate = false;
  services.power-profiles-daemon.enable = true;
  services.system76-scheduler.settings.cfsProfiles.enable = true;

  # Keep Wi-Fi associated during suspend and wake on a magic packet.
  # NetworkManager's magic-packet flag is 0x8; other triggers stay disabled.
  networking.networkmanager.settings.connection."wifi.wake-on-wlan" = 8;

  networking.firewall.allowedTCPPorts = [ 8765 ];

  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    # Open streaming ports only on Tailscale below.
    openFirewall = false;
    settings = {
      sunshine_name = "atlas";
      capture = "kms";
      encoder = "nvenc";
      upnp = "disabled";
      # Sunshine classifies Tailscale's 100.64.0.0/10 addresses as WAN.
      origin_web_ui_allowed = "wan";
      # Allow setup and pairing from Atlas's exact Tailscale web UI origin.
      csrf_allowed_origins = "https://100.92.181.17:47990";
    };
  };

  networking.firewall.interfaces.${config.services.tailscale.interfaceName} = {
    allowedTCPPorts = [
      47984 # HTTPS streaming API
      47989 # HTTP streaming API
      47990 # Sunshine setup and pairing UI
      48010 # RTSP
    ];
    allowedUDPPorts = [
      47998 # Video
      47999 # Control
      48000 # Audio
      48002 # Microphone
      48010 # RTSP
    ];
  };
}
