{ inputs, ... }:
{
  imports = [ inputs.codex-desktop-linux.homeManagerModules.default ];

  programs.codexDesktopLinux = {
    enable = true;
    computerUseUi.enable = true;

    linuxFeatures = [
      "remote-control-ui"
      "remote-mobile-control"
    ];

    remoteControl.enable = true;
  };

  home.sessionVariables.CODEX_CLI_PATH = "/etc/profiles/per-user/paul/bin/codex";
}
