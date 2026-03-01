{ pkgs, ... }:

let
  pname = "blinkdisk";
  version = "1.5.0";

  src = pkgs.fetchurl {
    url = "https://github.com/blinkdisk/blinkdisk/releases/download/v${version}/BlinkDisk-Linux-x86_64.AppImage";
    hash = "sha256-3fK2/zhmkWEEct0RMEnYVLLoyH3a+fuA73dqpJB7EyI=";
  };

  appimageContents = pkgs.appimageTools.extract {
    inherit pname version src;
  };
in
pkgs.appimageTools.wrapType2 {
  inherit pname version src;

  pkgs = pkgs;

  extraInstallCommands = ''
    install -m 444 -D ${appimageContents}/${pname}.desktop \
      -t $out/share/applications

    substituteInPlace $out/share/applications/${pname}.desktop \
      --replace 'Exec=AppRun' 'Exec=${pname}'

    source "${pkgs.makeWrapper}/nix-support/setup-hook"
    wrapProgram $out/bin/${pname} \
      --add-flags "--enable-features=UseOzonePlatform" \
      --add-flags "--ozone-platform=wayland"

    cp -r ${appimageContents}/usr/share/icons $out/share
  '';

  extraPkgs =
    pkgs: with pkgs; [
      unzip
      autoPatchelfHook
      asar

      (buildPackages.wrapGAppsHook3.override {
        inherit (buildPackages) makeWrapper;
      })
    ];
}
