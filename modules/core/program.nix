{ inputs, ... }:
{
  imports = [
    inputs.chatgpt-desktop-app.nixosModules.default
    inputs.inlark.nixosModules.default
  ];

  programs = {
    chatgpt-desktop-app.enable = true;
    dconf.enable = true;
    # Temporarily disabled: upstream reader-body test times out during the build.
    inlark.enable = false;
    # Default shell
    zsh.enable = true;
  };
}
