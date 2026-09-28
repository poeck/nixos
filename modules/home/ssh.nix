{ lib, pkgs, ... }:
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

  # OpenSSH rejects the Nix store owner's UID for a user SSH config.
  # Home Manager links this file during activation, then we copy it into place.
  home.file.".ssh/config".force = true;
  home.activation.copySshConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run ${pkgs.bash}/bin/bash -eu -c '
      ssh_config="$HOME/.ssh/config"
      if [ -L "$ssh_config" ]; then
        ssh_config_tmp="$(${pkgs.coreutils}/bin/mktemp "$ssh_config.XXXXXX")"
        ${pkgs.coreutils}/bin/cp --dereference "$ssh_config" "$ssh_config_tmp"
        ${pkgs.coreutils}/bin/chmod 600 "$ssh_config_tmp"
        ${pkgs.coreutils}/bin/mv -f "$ssh_config_tmp" "$ssh_config"
      fi
    '
  '';

  services.ssh-agent.enable = true;
}
