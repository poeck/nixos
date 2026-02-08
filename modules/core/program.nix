{ ... }:
{
  programs = {
    dconf.enable = true;
    # Default shell
    zsh.enable = true;
    # Automation tool (like xdotool for Wayland)
    ydotool.enable = true;

    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };
}
