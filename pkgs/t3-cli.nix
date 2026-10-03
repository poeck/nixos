{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  systemd,
}:
let
  # Keep this version in sync with the nightly desktop in the t3code flake.
  version = "0.0.45-nightly.20261002.2572";
  releases = {
    x86_64-linux = {
      arch = "x64";
      hash = "sha256-1mpg8gKsbPqEx2KtcIr3fBfIZM9LQS5dmjB9U3xZp0E=";
    };
    aarch64-linux = {
      arch = "arm64";
      hash = "sha256-jvtLa85rrc+9/mU72QuNzUsldMDoQjJfuRsnaQU6wMQ=";
    };
  };
  release = releases.${stdenv.hostPlatform.system};
in
stdenv.mkDerivation {
  pname = "t3-cli";
  inherit version;

  src = fetchurl {
    url = "https://github.com/pingdotgg/t3code/releases/download/v${version}/t3-${version}-linux-${release.arch}.tar.gz";
    hash = release.hash;
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];
  buildInputs = [ stdenv.cc.cc.lib ];
  dontBuild = true;
  # Preserve the embedded Node.js single-executable application payload.
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/libexec/t3" "$out/bin"
    cp -r t3 client node_modules resource-monitor "$out/libexec/t3/"
    # NixOS uses glibc; the archive also contains an unused musl fallback.
    rm -rf "$out/libexec/t3/node_modules/"@ff-labs/*-musl

    makeWrapper "$out/libexec/t3/t3" "$out/bin/t3" --run '
      case "''${1-}:''${2-}" in
        update:*|uninstall:*|service:install|service:uninstall)
          echo "T3 Code is managed by NixOS. Change the Nix configuration and rebuild instead." >&2
          exit 1
          ;;
        service:status|service:restart)
          action=$2
          shift 2
          exec ${systemd}/bin/systemctl --user "$action" t3code.service "$@"
          ;;
      esac
    '

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    "$out/bin/t3" --version | grep -F "${version}"
    runHook postInstallCheck
  '';

  meta = {
    description = "T3 Code CLI and server runtime, managed by NixOS";
    homepage = "https://github.com/pingdotgg/t3code";
    license = lib.licenses.mit;
    mainProgram = "t3";
    platforms = builtins.attrNames releases;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
