{ pkgs, lib, ... }:
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
    extensions =
      let
        createChromiumExtensionFor =
          browserVersion:
          {
            id,
            sha256,
            version,
          }:
          {
            inherit id;
            crxPath = builtins.fetchurl {
              url = "https://clients2.google.com/service/update2/crx?response=redirect&acceptformat=crx2,crx3&prodversion=${browserVersion}&x=id%3D${id}%26installsource%3Dondemand%26uc";
              name = "${id}.crx";
              inherit sha256;
            };
            inherit version;
          };
        createChromiumExtension = createChromiumExtensionFor (
          lib.versions.major pkgs.ungoogled-chromium.version
        );
      in
      [
        (createChromiumExtension {
          # ublock origin
          id = "cjpalhdlnbpafiamejdnhcphjbkeiagm";
          sha256 = "sha256:0pba857r9n2hlfc6szxicf69yqg6kqyz74cz13k4alacjrdkk2n3";
          version = "1.68.0";
        })
        (createChromiumExtension {
          # 1password
          id = "aeblfdkhhhdcdjpifhhbdiojplfjncoa";
          sha256 = "sha256:1ingz45cv6zvjkkrjdqs9fj4rzqj6ng0v1mc6mq6sczhj40m20kv";
          version = "8.11.22.27";
        })
        (createChromiumExtension {
          # AuthFill
          id = "doanledhbgobnfeicgdchpilkjkbjddg";
          sha256 = "sha256:0ssb6ksvqng3px5rgma718v0zwnjb5xgckxvamdzp5kd34g3x9sk";
          version = "1.0.0";
        })
      ];
  };
}
