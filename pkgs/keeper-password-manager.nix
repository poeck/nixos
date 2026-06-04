{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  gdk-pixbuf,
  glib,
  gtk3,
  libdrm,
  libgbm,
  libsecret,
  libxkbcommon,
  mesa,
  nspr,
  nss,
  pango,
  pcsclite,
  libx11,
  libxscrnsaver,
  libxcomposite,
  libxcursor,
  libxdamage,
  libxext,
  libxfixes,
  libxi,
  libxrandr,
  libxrender,
  libxtst,
  libxcb,
}:

stdenv.mkDerivation rec {
  pname = "keeper-password-manager";
  version = "18.0.2";

  src = fetchurl {
    url = "https://download.keepersecurity.com/desktop_electron/Linux/repo/deb/keeperpasswordmanager_${version}_amd64.deb";
    hash = "sha256-MWVGy4QMvz6wc34diXt1G80fZGzQTZvj5MWdQM6ZXqY=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    makeWrapper
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    gdk-pixbuf
    glib
    gtk3
    libdrm
    libgbm
    libsecret
    libxkbcommon
    mesa
    nspr
    nss
    pango
    pcsclite
    libx11
    libxscrnsaver
    libxcomposite
    libxcursor
    libxdamage
    libxext
    libxfixes
    libxi
    libxrandr
    libxrender
    libxtst
    libxcb
  ];

  dontUnpack = true;
  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    dpkg-deb --fsys-tarfile $src | tar --extract --no-same-owner --no-same-permissions -C $out
    mkdir -p $out/bin
    ln -s $out/usr/lib/keeperpasswordmanager/keeperpasswordmanager $out/bin/keeperpasswordmanager

    substituteInPlace $out/usr/share/applications/keeperpasswordmanager.desktop \
      --replace-fail "Exec=keeperpasswordmanager %U" "Exec=$out/bin/keeperpasswordmanager %U"

    runHook postInstall
  '';

  postFixup = ''
    wrapProgram $out/usr/lib/keeperpasswordmanager/keeperpasswordmanager \
      --add-flags "--enable-features=UseOzonePlatform" \
      --add-flags "--ozone-platform-hint=auto"
  '';

  meta = {
    description = "Keeper Password Manager desktop application";
    homepage = "https://www.keepersecurity.com/download.html";
    license = lib.licenses.unfree;
    mainProgram = "keeperpasswordmanager";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
