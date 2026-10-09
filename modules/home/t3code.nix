{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  desktop = inputs.t3code.packages.${pkgs.stdenv.hostPlatform.system}.nightly;
  servicePath = lib.concatStringsSep ":" (
    [ "/etc/profiles/per-user/${config.home.username}/bin" ]
    ++ config.home.sessionPath
    ++ [
      "${config.home.homeDirectory}/.nix-profile/bin"
      "/run/wrappers/bin"
      "/run/current-system/sw/bin"
    ]
  );
in
{
  assertions = [
    {
      assertion = pkgs.t3-cli.version == desktop.version;
      message = "Update pkgs/t3-cli.nix to match the T3 Code nightly desktop version (${desktop.version}).";
    }
  ];

  home.packages = [ pkgs.t3-cli ];

  systemd.user.services.t3code = {
    Unit = {
      Description = "T3 Code server";
      StartLimitIntervalSec = 300;
      StartLimitBurst = 5;
    };
    Service = {
      Type = "simple";
      WorkingDirectory = "%h";
      Environment = [
        "T3CODE_HOME=%h/.t3"
        "PATH=${servicePath}"
      ];
      # Run the immutable Nix runtime directly, bypassing the self-update launcher.
      # The desktop uses port 3773, so keep the standalone service on 3774.
      ExecStart = "${lib.getExe pkgs.t3-cli} serve --host 127.0.0.1 --port 3774";
      KillMode = "mixed";
      OOMPolicy = "continue";
      Restart = "always";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };

  # Take ownership of the unit and startup link created by `t3 service install`.
  xdg.configFile."systemd/user/t3code.service".force = true;
  xdg.configFile."systemd/user/default.target.wants/t3code.service".force = true;

  home.activation.migrateT3Code = lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ] ''
    t3codeServiceMigrated=0
    unit="$HOME/.config/systemd/user/t3code.service"
    if [ -f "$unit" ] && [ ! -L "$unit" ]; then
      run ${pkgs.coreutils}/bin/mv --backup=numbered "$unit" "$unit.pre-nix"
      t3codeServiceMigrated=1
    fi

    # Old launchers would otherwise precede the managed CLI on the shell PATH.
    for launcher in "$HOME/.local/bin/t3" "$HOME/.npm-global/bin/t3"; do
      if [ -L "$launcher" ]; then
        target=$(${pkgs.coreutils}/bin/readlink "$launcher")
        case "$target" in
          "$HOME"/.t3/runtime/versions/*/t3|"$HOME"/.local/bin/t3)
            run ${pkgs.coreutils}/bin/mv --backup=numbered "$launcher" "$launcher.pre-nix"
            ;;
        esac
      fi
    done
  '';

  # An installer-created unit is absent from the old Home Manager generation.
  # Explicitly restart it once so adoption also replaces the running runtime.
  home.activation.restartMigratedT3Code = lib.hm.dag.entryAfter [ "reloadSystemd" ] ''
    if [ "''${t3codeServiceMigrated:-0}" = 1 ] && \
      ${pkgs.systemd}/bin/systemctl --user is-active --quiet t3code.service; then
      run ${pkgs.systemd}/bin/systemctl --user restart t3code.service
    fi
  '';
}
