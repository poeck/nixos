{ pkgs, ... }:
{
  services.printing = {
    enable = true;
    drivers = [
      # Many different printers
      pkgs.gutenprint
      # Some brother printers
      pkgs.brlaser
    ];
  };

  # Autodiscovery of network printers
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
}
