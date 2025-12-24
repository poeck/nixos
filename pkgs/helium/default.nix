{
lib,
unzip,
autoPatchelfHook,
stdenv,
fetchurl,
xorg,
libgbm,
cairo,
libudev-zero,
libxkbcommon,
nspr,
nss,
libcupsfilters,
pango,
qt5,
alsa-lib,
atk,
at-spi2-core,
at-spi2-atk,
 }:

stdenv.mkDerivation rec {
    name = "helium";
    version = "0.7.6.1";

    src = fetchurl {
	url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-x86_64_linux.tar.xz";
        sha256 = "sha256-RL0MMsYmcboZt7aq2R/6onLX1bTxlEbhlwB7yBb84os=";
    };

    nativeBuildInputs = [ 
        unzip
        autoPatchelfHook
    ];

    autoPatchelfIgnoreMissingDeps = [
        "libQt6Core.so.6"
        "libQt6Gui.so.6"
        "libQt6Widgets.so.6"
    ];
    
    runtimeDependencies = [  ];
    buildInputs = [
        unzip
        xorg.libxcb
        xorg.libX11
        xorg.libXcomposite
        xorg.libXdamage
        xorg.libXext
        xorg.libXfixes
        xorg.libXrandr
        libgbm
        cairo
        pango
        libudev-zero
        libxkbcommon
        nspr
        nss
        libcupsfilters
        alsa-lib
        atk
        at-spi2-core
        at-spi2-atk
        qt5.qtbase
        qt5.qttools
        qt5.qtx11extras
        qt5.wrapQtAppsHook
    ];

    installPhase = ''
        runHook preInstall
        mkdir -p $out/bin
        
        # Move all files except conflicting binaries
        for file in *; do
            case "$file" in
                xdg-*)
                    # Skip xdg-utils binaries to avoid conflicts
                    continue
                    ;;
                *)
                    cp -r "$file" $out/bin/
                    ;;
            esac
        done
        
        mv $out/bin/chrome $out/bin/helium
        mkdir -p $out/share/applications
        
        cat <<INI> $out/share/applications/helium.desktop
[Desktop Entry]
Name=Helium
GenericName=Web Browser
Terminal=false
Icon=$out/bin/product_logo_256.png
Exec=$out/bin/helium
Type=Application
Categories=Network;WebBrowser;
INI
    
        '';


    meta = with lib; {
        homepage = "https://github.com/imputnet/helium-linux";
        description = "Helium Browser";
        platforms = platforms.linux;
    };
}
