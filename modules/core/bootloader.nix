{ pkgs, inputs, ... }:
let
  minegrubTheme = pkgs.stdenvNoCC.mkDerivation {
    pname = "minegrub-theme";
    version = "unstable-${inputs.minegrub.lastModifiedDate or "unknown"}";
    src = inputs.minegrub;

    nativeBuildInputs = [
      pkgs.fastfetch
      (pkgs.python3.withPackages (pythonPackages: [ pythonPackages.pillow ]))
    ];

    patchPhase = ''
      runHook prePatch
      sed -i '$d' minegrub/update_theme.py
      sed -i '/^+ image {/,/^}$/s/top = 40%+[0-9]\+/top = 40%+746/' minegrub/theme.txt
      runHook postPatch
    '';

    buildPhase = ''
      runHook preBuild
      python minegrub/update_theme.py \
        "background_options/1.8  - [Classic Minecraft].png" \
        "I use NixOS, btw!"
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/grub/themes/minegrub
      cp minegrub/*.png minegrub/*.pf2 minegrub/theme.txt $out/grub/themes/minegrub
      runHook postInstall
    '';
  };
in
{
  imports = [
    inputs.mineplymouth.nixosModules.default
  ];

  boot = {
    loader = {
      grub = {
        # Use grub as the bootloader
        enable = true;
        # Enables efi support
        efiSupport = true;
        # Switch to UEFI mode
        device = "nodev";
        # Auto scan for windows
        useOSProber = true;
        # Theme
        theme = "${minegrubTheme}/grub/themes/minegrub";
        splashImage = "${minegrubTheme}/grub/themes/minegrub/background.png";
      };
      # Timeout after 30s
      timeout = 30;
      # Allow writing boot entries
      efi.canTouchEfiVariables = true;
    };

    # Show GUI while booting
    plymouth = {
      enable = true;
      theme = "mc";
      extraConfig = "ShowDelay=0";
      themePackages = [
        inputs.mineplymouth.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    };

    kernelParams = [
      # Don't show any logs at boot
      "quiet"
      # Only show errors
      "loglevel=3"
      # Allow plymouth to use simpledrm
      "plymouth.use-simpledrm"
    ];

    # Supress kernel logs at boot
    consoleLogLevel = 0;

    initrd = {
      verbose = false;
      # Experimental feature that makes initrd use
      # systemd for PID to start plymouth earlier
      #
      # This is required to
      # 1. Enter the luks passphrase in plymouth instead of tty
      # 2. Unlock the gnome keyring via the luks passphrase
      systemd.enable = true;
    };

    # Use the latest kernel
    kernelPackages = pkgs.linuxPackages_latest;

    # Enable support for windows
    supportedFilesystems = [ "ntfs" ];
  };
}
