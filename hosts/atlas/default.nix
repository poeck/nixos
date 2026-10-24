{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./graphics.nix
    ./remote-unlock.nix
    ./remote-power-guard.nix
    ../../modules/core
    ../../modules/core/media.nix
  ];

  # Desktop: no ASUS laptop daemon, TLP, or laptop-specific ACPI modules.
  powerManagement.enable = true;
  systemd.sleep.settings.Sleep.AllowSuspendThenHibernate = false;
  services.power-profiles-daemon.enable = true;
  services.system76-scheduler.settings.cfsProfiles.enable = true;

  # The G915's wired connection causes unwanted wakes when charging alongside
  # its receiver. Use mouse wake while charging; wireless keyboard wake remains
  # available when the cable is unplugged.
  services.udev.extraRules = ''
    ACTION=="add|bind|change", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="046d", ATTR{idProduct}=="c343", TEST=="power/wakeup", ATTR{power/wakeup}="disabled"
  '';

  # Keep Wi-Fi associated during suspend and wake on a magic packet.
  # NetworkManager's magic-packet flag is 0x8; other triggers stay disabled.
  networking.networkmanager.settings.connection."wifi.wake-on-wlan" = 8;

  services.sunshine = {
    enable = true;
    autoStart = true;
    # WLR also captures Hyprland's virtual output and needs no KMS capability.
    capSysAdmin = false;
    package = pkgs.symlinkJoin {
      name = "sunshine-nvenc-${pkgs.sunshine.version}";
      paths = [ pkgs.sunshine ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      # Sunshine's bundled FFmpeg dlopens these driver libraries. The default
      # non-CUDA build omits the driver runpath, although NVENC itself works.
      postBuild = ''
        wrapProgram $out/bin/sunshine \
          --prefix LD_LIBRARY_PATH : /run/opengl-driver/lib
      '';
      meta.mainProgram = "sunshine";
    };
    # Open streaming ports only on Tailscale below.
    openFirewall = false;
    settings = {
      sunshine_name = "atlas";
      capture = "wlr";
      encoder = "nvenc";
      # The user-service launcher selects ATLAS-REMOTE in remote mode and
      # resolves the AOC connector by description in normal desktop mode.
      output_name = "DP-2";
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
