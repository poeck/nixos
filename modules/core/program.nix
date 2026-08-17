{ inputs, ... }:
{
  imports = [ inputs.chatgpt-desktop-app.nixosModules.default ];

  programs = {
    chatgpt-desktop-app.enable = true;
    dconf.enable = true;
    # Default shell
    zsh.enable = true;
  };
}
