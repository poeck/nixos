{ ... }:
{
  programs = {
    dconf.enable = true;
    # Default shell
    zsh.enable = true;

    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };
}
