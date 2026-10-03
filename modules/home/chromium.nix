{ pkgs, ... }:
{
  programs.chromium = {
    enable = true;
    package = pkgs.ungoogled-chromium.override {
      enableWideVine = true;
      commandLineArgs = [
        "--enable-features=AcceleratedVideoEncoder"
        "--ignore-gpu-blocklist"
        "--enable-zero-copy"
        "--enable-features=TouchpadOverscrollHistoryNavigation"
      ];
    };
    # Fixed downloads avoid hash mismatches when the Web Store updates a package.
    extensions = map (extension: {
      inherit (extension) id version;
      crxPath = "${pkgs.fetchurl {
        inherit (extension) url sha256;
        name = "${extension.id}.crx";
      }}";
    }) (builtins.fromJSON (builtins.readFile ./chromium-extensions.json));
  };
}
