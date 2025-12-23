{ config, pkgs, ... }:
{
    services.printing = {
      enable = true;
      drivers = [
          # Many different printers
          pkgs.gutenprint
          # Some brother printers
          pkgs.brlaser
          # More brother printers
          pkgs.brgenml1lpr
          pkgs.brgenml1cupswrapper
      ];
    };

    # Autodiscovery of network printers
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
}
