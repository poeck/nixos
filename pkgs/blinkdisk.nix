{
  stdenv,
  lib,
  appimageTools,
  fetchurl,
  makeDesktopItem,
  copyDesktopItems,
}:
let
  pname = "blinkdisk";
  version = "v0.6.1";

  architectures = {
    "x86_64-linux" = {
      arch = "x86_64";
      hash = "sha256-OZoGYmVcFcDRHHzUsO9TYKp622LBL7cqDrthjwf4SuA=";
    };
  };

  src =
    let
      inherit (architectures.${stdenv.hostPlatform.system}) arch hash;
    in
    fetchurl {
      url = "https://github.com/blinkdisk/blinkdisk/releases/download/${version}/BlinkDisk-Linux-${arch}.AppImage";
      inherit hash;
    };
in
appimageTools.wrapType2 {
  inherit pname version src;
  nativeBuildInputs = [ copyDesktopItems ];
  desktopItems = [
    (makeDesktopItem {

    })
  ];
  meta = {
    platforms = lib.attrNames architectures;
  };
}
