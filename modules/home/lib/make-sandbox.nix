{ pkgs, inputs }:
let
  inherit (pkgs) lib;
  mkNixPak = inputs.nixpak.lib.nixpak {
    inherit lib pkgs;
  };
in
{
  package,
  name ? package.pname,
  appId ? "com.nixpak.${name}",
  permissions ? [ ],
  extraConfig ? _: { },
}:
mkNixPak {
  config =
    {
      sloth,
      ...
    }@args:
    let
      # Host path that will be bind-mounted as an xdg dir inside the sandbox.
      # Gives each app its own isolated config/cache/data, separate from
      # the real ~/.config etc. on the host. Wrapped in `sloth.mkdir` so the
      # launcher creates the dir (0700) before bwrap binds it — otherwise
      # bubblewrap's --bind-try silently skips missing sources and nothing
      # persists.
      stateDir = sub: sloth.mkdir (sloth.concat' sloth.homeDir "/.local/state/nixpak/${name}/${sub}");

      guiConfig = lib.optionalAttrs (lib.elem "gui" permissions) {
        # Bind /dev/dri and the Mesa/driver userspace so GPU acceleration works.
        gpu.enable = true;
        # Expose host fontconfig + font packages so text renders with system fonts.
        fonts.enable = true;

        # Proxy a session dbus socket into the sandbox, filtered by the policies
        # below. Without this the app can't reach any dbus services at all.
        dbus.enable = true;
        dbus.policies = {
          # xdg-desktop-portal: file pickers, OpenURI, screenshot, settings, etc.
          "org.freedesktop.portal.*" = "talk";
          # theme, fonts, cursor settings for GTK.
          "ca.desrt.dconf" = "talk";
        }
        // lib.optionalAttrs (lib.elem "notifications" permissions) {
          "org.freedesktop.Notifications" = "talk";
        }
        // lib.optionalAttrs (lib.elem "keyring" permissions) {
          # Secret Service API (gnome-keyring, kwallet) for storing credentials.
          "org.freedesktop.secrets" = "talk";
        };

        # Wayland display socket — required for the app to draw anything.
        bubblewrap.sockets.wayland = true;

        # GTK walks $XDG_DATA_DIRS/icons for themes and $XDG_DATA_DIRS/mime for
        # content-type detection. Without these:
        #   - symbolic icons render as broken placeholders ("Could not find
        #     the icon 'mail-archive-symbolic-ltr'", "hicolor theme was not
        #     found").
        #   - libraries like folks log "content type appears to be
        #     application/octet-stream ... Have you installed shared-mime-info?"
        # App wrappers prefix their own entries onto this, so setting it here
        # doesn't clobber package-local resources.
        bubblewrap.env.XDG_DATA_DIRS = lib.concatStringsSep ":" [
          "${pkgs.adwaita-icon-theme}/share"
          "${pkgs.hicolor-icon-theme}/share"
          "${pkgs.shared-mime-info}/share"
        ];
      };

      audioConfig = lib.optionalAttrs (lib.elem "audio" permissions) {
        bubblewrap = {
          # PipeWire-native socket — for apps that speak PipeWire directly
          # (and screen capture via portal).
          sockets.pipewire = true;
          # PulseAudio socket (served by pipewire-pulse on this system) — most
          # audio clients, including pavucontrol, connect here rather than to
          # the native PipeWire socket.
          sockets.pulse = true;

          # Apps using ALSA directly (e.g. anything built on cpal) open
          # `pcm.default`, which on NixOS is routed through PipeWire by
          # /etc/alsa/conf.d/*. The sandbox has no /etc/alsa, so we drop in an
          # asound.conf that pulls in the same pipewire config files NixOS
          # installs on the host — by absolute store path, since the whole
          # nix store is already bound inside the sandbox. ALSA_PLUGIN_DIR
          # tells libasound where to find libasound_module_pcm_pipewire.so.
          bind.ro = [
            [
              "${pkgs.writeText "asound.conf" ''
                <${pkgs.pipewire}/share/alsa/alsa.conf.d/50-pipewire.conf>
                <${pkgs.pipewire}/share/alsa/alsa.conf.d/99-pipewire-default.conf>
              ''}"
              "/etc/asound.conf"
            ]
          ];
          env.ALSA_PLUGIN_DIR = "${pkgs.pipewire}/lib/alsa-lib";
        };
      };

      baseConfig = {
        app.package = package;
        flatpak.appId = appId;

        # Pass through LANG/LC_* and the corresponding locale-archive.
        locale.enable = true;
        # Mount the host CA bundle so TLS works (HTTPS, sync, auto-update, etc).
        etc.sslCertificates.enable = lib.elem "network" permissions;

        bubblewrap = {
          network = lib.elem "network" permissions;

          # Per-app persistent storage. Left side = host path (isolated per app),
          # right side = the xdg dir the app sees inside the sandbox.
          bind.rw = [
            [
              (stateDir "config")
              sloth.xdgConfigHome
            ]
            [
              (stateDir "cache")
              sloth.xdgCacheHome
            ]
            [
              (stateDir "data")
              sloth.xdgDataHome
            ]
          ];
        };
      };
    in
    lib.foldl' lib.recursiveUpdate baseConfig [
      guiConfig
      audioConfig
      (extraConfig args)
    ];
}
