{ inputs, ... }:
{
  imports = [ inputs.codex-desktop-linux.homeManagerModules.default ];

  programs.codexDesktopLinux.enable = true;

  home.sessionVariables.CODEX_CLI_PATH = "/etc/profiles/per-user/paul/bin/codex";
}
