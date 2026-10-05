{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  # Keep component/extension updates enabled and do not hide outdated-browser
  # warnings. Browser binaries themselves are updated through the flake pin.
  helium =
    inputs.helium-browser.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs
      (old: {
        installPhase = lib.replaceStrings (map (flag: "--add-flags \"${flag}\"") [
          "--disable-component-update"
          "--simulate-outdated-no-au='Tue, 31 Dec 2099 23:59:59 GMT'"
          "--check-for-update-interval=0"
          "--disable-background-networking"
        ]) [ "" "" "" "" ] old.installPhase;
      });

  # Helium already bundles classic uBlock Origin as a component extension.
  # Share the requested additional extensions between Personal and Otark.
  extensions = lib.filter (
    extension:
    lib.elem extension.name [
      "1Password"
      "AuthFill"
      "Codex"
      "Claude"
    ]
  ) (builtins.fromJSON (builtins.readFile ./chromium-extensions.json));

  profileDefaults = pkgs.writeText "helium-profile-defaults.json" (
    builtins.toJSON {
      Personal = {
        profile = {
          name = "Personal";
          using_default_name = false;
        };
        browser.theme.is_grayscale2 = true;
      };
      Otark = {
        profile = {
          name = "Otark";
          using_default_name = false;
        };
        extensions = {
          theme.id = "user_color_theme_id";
          # External extension manifests are shared by the browser. Chromium's
          # per-profile uninstall list keeps AuthFill out of this profile.
          external_uninstalls = [ "doanledhbgobnfeicgdchpilkjkbjddg" ];
        };
        browser.theme = {
          is_grayscale2 = false;
          # Chromium stores SkColor as a signed 32-bit ARGB integer: #16a34a.
          user_color2 = -15293622;
        };
      };
    }
  );

  seedProfiles = pkgs.writeShellScript "seed-helium-profiles" ''
    exec ${pkgs.python3}/bin/python ${./lib/seed-helium-profiles.py} \
      ${profileDefaults} "''${HELIUM_CONFIG_HOME:-''${XDG_CONFIG_HOME:-${config.xdg.configHome}}}/net.imput.helium"
  '';

  profileLaunchers =
    map
      (
        name:
        pkgs.writeShellScriptBin "helium-${lib.toLower name}" ''
          ${seedProfiles}
          exec ${lib.getExe helium} --profile-directory=${lib.escapeShellArg name} "$@"
        ''
      )
      [
        "Personal"
        "Otark"
      ];
in
{
  home.packages = [ helium ] ++ profileLaunchers;

  xdg.configFile =
    lib.listToAttrs (
      map (extension: {
        name = "net.imput.helium/External Extensions/${extension.id}.json";
        value.text = builtins.toJSON {
          external_crx = "${pkgs.fetchurl {
            inherit (extension) url sha256;
            name = "${extension.id}.crx";
          }}";
          external_version = extension.version;
        };
      }) extensions
    )
    // {
      "net.imput.helium/NativeMessagingHosts/com.1password.1password.json".text = builtins.toJSON {
        name = "com.1password.1password";
        description = "1Password BrowserSupport";
        path = "/run/wrappers/bin/1Password-BrowserSupport";
        type = "stdio";
        allowed_origins = [ "chrome-extension://aeblfdkhhhdcdjpifhhbdiojplfjncoa/" ];
      };
      # Use the native host supplied and updated by the official OpenAI plugin.
      "net.imput.helium/NativeMessagingHosts/com.openai.codexextension.json".text = builtins.toJSON {
        name = "com.openai.codexextension";
        description = "ChatGPT browser native messaging host";
        path = "${config.home.homeDirectory}/.codex/plugins/cache/openai-bundled/chrome/latest/extension-host/linux/x64/extension-host";
        type = "stdio";
        allowed_origins = [ "chrome-extension://hehggadaopoacecdllhhajmbjkdcmajg/" ];
      };
    };

  # Seed new profiles once and apply targeted extension exclusions only while
  # the browser is stopped. Preserve all other preferences and Local State.
  home.activation.seedHeliumProfiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${seedProfiles}
  '';

  xdg.desktopEntries = lib.genAttrs [ "helium-personal" "helium-otark" ] (
    launcher:
    let
      name = if launcher == "helium-personal" then "Personal" else "Otark";
    in
    {
      name = "Helium (${name})";
      genericName = "Web Browser";
      exec = "${launcher} %U";
      icon = "helium";
      terminal = false;
      categories = [
        "Network"
        "WebBrowser"
      ];
      mimeType = [
        "text/html"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
      ];
      startupNotify = true;
    }
  );
}
