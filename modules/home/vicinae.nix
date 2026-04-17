{ pkgs, inputs, username, ... }:
let
  inherit (pkgs) lib;
  makeSandbox = import ./lib/make-sandbox.nix { inherit pkgs inputs; };

  # Single dispatcher: invoked via a symlink named after the target binary;
  # uses argv[0] to know what to run on the host. systemd-run --user submits
  # a transient unit to the user systemd manager (which lives outside the
  # sandbox), so the launched process runs on the host with the user's
  # normal env, not inside vicinae's sandbox.
  vicinaeHostSpawn = pkgs.writeShellScript "vicinae-host-spawn" ''
    exec ${pkgs.systemd}/bin/systemd-run \
      --user --collect --quiet \
      --unit="vicinae-spawn-$$" \
      -- "$(basename "$0")" "$@"
  '';

  # Wraps vicinae so that on each launch it (re)builds a shim dir under
  # $XDG_RUNTIME_DIR/vicinae/host-shims/ — one symlink per binary in the
  # bound host /bin dirs, all pointing to the dispatcher above. PATH is
  # set so vicinae's QProcess::startDetached(name, ...) resolves the shim
  # instead of exec'ing inside the sandbox. Falls back to the original
  # PATH for vicinae's own helpers.
  vicinaeWrapped = pkgs.symlinkJoin {
    name = "vicinae-host-launching";
    paths = [ pkgs.vicinae ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/vicinae --run '
        shim_dir="$XDG_RUNTIME_DIR/vicinae/host-shims"
        rm -rf "$shim_dir"
        mkdir -p "$shim_dir"
        for bd in /run/host/system-bin /run/host/user-bin; do
          [ -d "$bd" ] || continue
          for f in "$bd"/*; do
            ln -sfn ${vicinaeHostSpawn} "$shim_dir/$(basename "$f")"
          done
        done
        export PATH="$shim_dir:$PATH"
      '
    '';
  };
in
{
  home.packages = [
    (makeSandbox {
      package = vicinaeWrapped;
      name = "vicinae";
      permissions = [
        "gui"
      ];
      extraConfig =
        { sloth, ... }:
        {
          dbus.policies = {
            # "show in file manager" via xdg.
            "org.freedesktop.FileManager1" = "talk";
            # Lets the wrapper's shims call `systemd-run --user` so launched
            # apps run as transient units on the host, outside the sandbox.
            "org.freedesktop.systemd1" = "talk";
          };
          bubblewrap.bind.ro = [
            # Power management (suspend/hibernate)
            "/run/dbus/system_bus_socket"
            # Hyprland event/control sockets at $XDG_RUNTIME_DIR/hypr/<sig>/
            # — vicinae's EventListener connects to .socket2.sock.
            (sloth.concat' sloth.runtimeDir "/hypr")
            # App discovery: NixOS system + home-manager profile share dirs.
            # Each contains applications/, icons/, etc. — added to
            # XDG_DATA_DIRS below so vicinae's XDG scan picks them up.
            "/run/current-system/sw/share"
            "/etc/profiles/per-user/${username}/share"
            # User-specific .desktop files and icon themes. Bound to a fresh
            # path because the sandbox's ~/.local/share is already overlaid
            # with a per-app private dir (see make-sandbox.nix).
            [
              (sloth.concat' sloth.homeDir "/.local/share")
              "/run/host/local-share"
            ]
            # Host /bin dirs — bound off-PATH so the vicinae wrapper can
            # enumerate binary names and create shims. Not added to PATH;
            # instead the wrapper's shim dir takes precedence so each name
            # routes through systemd-run rather than exec'ing in-sandbox.
            [ "/run/current-system/sw/bin" "/run/host/system-bin" ]
            [ "/etc/profiles/per-user/${username}/bin" "/run/host/user-bin" ]
          ];
          # Expose vicinae's IPC socket dir to the host so `vicinae open` from
          # outside the sandbox can reach $XDG_RUNTIME_DIR/vicinae/vicinae.sock.
          bubblewrap.bind.rw = [
            (sloth.mkdir (sloth.concat' sloth.runtimeDir "/vicinae"))
          ];
          bubblewrap.env.XDG_DATA_DIRS = lib.concatStringsSep ":" [
            # Existing icon/mime fallbacks from the gui preset.
            "${pkgs.adwaita-icon-theme}/share"
            "${pkgs.hicolor-icon-theme}/share"
            "${pkgs.shared-mime-info}/share"
            # Host application/icon dirs.
            "/run/current-system/sw/share"
            "/etc/profiles/per-user/${username}/share"
            "/run/host/local-share"
          ];
        };
    }).config.env
  ];
}
