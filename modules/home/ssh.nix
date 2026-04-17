{ ... }:
{
  programs = {
    ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        "*" = {
          identityAgent = "~/.1password/agent.sock";
        };
      };
    };

    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };

  services.ssh-agent.enable = true;
}
