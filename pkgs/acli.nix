{
  lib,
  stdenvNoCC,
  fetchurl,
  installShellFiles,
  buildFHSEnv,
}:
let
  version = "1.3.22-stable";

  meta = {
    description = "Atlassian Command Line Interface";
    homepage = "https://developer.atlassian.com/cloud/acli/";
    license = lib.licenses.unfree;
    mainProgram = "acli";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };

  unwrapped = stdenvNoCC.mkDerivation {
    pname = "acli-unwrapped";
    inherit version meta;

    src = fetchurl {
      url = "https://acli.atlassian.com/linux/${version}/acli_${version}_linux_amd64.tar.gz";
      hash = "sha256-3p4KYKVW5BGUKLkHL2ynh+dbn5pTiqcevMgITeuMoaY=";
    };

    nativeBuildInputs = [ installShellFiles ];

    installPhase = ''
      runHook preInstall

      install -Dm755 acli $out/bin/acli

      installShellCompletion --cmd acli \
        --bash <($out/bin/acli completion bash) \
        --fish <($out/bin/acli completion fish) \
        --zsh <($out/bin/acli completion zsh)

      mkdir -p $out/share/powershell
      $out/bin/acli completion powershell > $out/share/powershell/acli.Completion.ps1

      runHook postInstall
    '';
  };
in
buildFHSEnv {
  pname = "acli";
  inherit version meta;

  targetPkgs =
    pkgs: with pkgs; [
      unwrapped
      cacert
      openssl
      zlib
      libffi
      sqlite
    ];

  runScript = "acli";
}
