{ lib, pkgs, ... }:
{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "Paul Koeck";
        email = "paul@koeck.dev";
      };

      init.defaultBranch = "main";
      merge.conflictstyle = "diff3";
      diff.colorMoved = "default";
      color.ui = true;
    };

    extraConfig = {
      gpg = {
        format = "ssh";
      };
      "gpg \"ssh\"" = {
        program = "${lib.getExe' pkgs._1password-gui "op-ssh-sign"}";
      };
      commit = {
        gpgsign = true;
      };
      user = {
        signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDjUGpuR4RN77nMKZsANUGpurG/pVP2K+/aOx9cmIxR6";
      };
    };
  };
}
