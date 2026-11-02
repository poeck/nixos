{ fetchurl, tpm2-tss, upstream, upstreamSource }:
let
  upstreamPatch = builtins.path {
    path = upstreamSource + "/pkgs/chatgpt-desktop-app/patch-plugin-permissions.cjs";
  };
in
# Retire this compatibility override when the upstream flake updates its release.
if upstream.version != "26.1023.51421" then
  upstream
else
  upstream.overrideAttrs (old: {
    version = "26.1027.51404";
    # Verified against the official Debian control metadata and file SHA-256.
    src = fetchurl {
      url = "https://persistent.oaistatic.com/codex-app-prod/linux/deb/latest/chatgpt_amd64.deb";
      hash = "sha256-RvHiLQKGmP6e2u/VhHrs4HxFCaMNNwnhBCIHGdjBKCI=";
    };
    buildInputs = old.buildInputs ++ [ tpm2-tss ];
    installPhase = builtins.replaceStrings
      [ "node ${upstreamPatch}" ]
      [ "node ${./chatgpt-patch-plugin-permissions.cjs}" ]
      old.installPhase;
    installCheckPhase = ''
      runHook preInstallCheck
      node ${./chatgpt-test-plugin-permissions.cjs} app/.vite/build ${./chatgpt-patch-plugin-permissions.cjs}
      runHook postInstallCheck
    '';
  })
