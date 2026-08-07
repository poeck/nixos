{ ... }:
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        IdentityAgent = "~/.1password/agent.sock";
      };
    };
  };

  services.ssh-agent.enable = true;
}
