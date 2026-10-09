{ config, username, ... }:
{
  services.openssh = {
    enable = true;
    # Allow SSH through the encrypted tailnet at home and away.
    openFirewall = false;
    settings = {
      AllowUsers = [ username ];
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      AuthenticationMethods = "publickey";
    };
  };

  users.users.${username}.openssh.authorizedKeys.keyFiles = [ ../../keys/paul.pub ];
  networking.firewall.interfaces.${config.services.tailscale.interfaceName}.allowedTCPPorts = [ 22 ];
}
