{ inputs, ... }:
{
  imports = [
    inputs.chatgpt-desktop-app.nixosModules.default
    inputs.inlark.nixosModules.default
  ];

  programs = {
    chatgpt-desktop-app.enable = true;
    dconf.enable = true;
    inlark.enable = true;
    # Default shell
    zsh.enable = true;
  };
}
