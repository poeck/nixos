{ inputs, pkgs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
  src = pkgs.applyPatches {
    name = "codex-desktop-linux-features";
    src = inputs.codex-desktop-linux;
    patches = [
      (pkgs.writeText "features.patch" ''
        diff --git a/flake.nix b/flake.nix
        index 32ce0bd..3f13b2a 100644
        --- a/flake.nix
        +++ b/flake.nix
        @@ -585,6 +585,13 @@
                   enableComputerUseUi = true;
                   linuxFeatureIds = [ "remote-mobile-control" ];
                 };
        +
        +        codexDesktopFull = mkCodexDesktop {
        +          linuxFeatureIds = [
        +            "appshots"
        +            "zed-opener"
        +          ];
        +        };
         
                 installer = pkgs.writeShellApplication {
                   name = "codex-desktop-installer";
        @@ -611,6 +618,7 @@
                   codex-desktop-computer-use-ui = codexDesktopComputerUseUi;
                   codex-desktop-remote-mobile-control = codexDesktopRemoteMobileControl;
                   codex-desktop-computer-use-ui-remote-mobile-control = codexDesktopComputerUseUiRemoteMobileControl;
        +          full = codexDesktopFull;
                   installer = installer;
                 };
         
      '')
    ];
  };
  flake =
    (import "${src}/flake.nix").outputs {
      self = {
        rev = inputs.codex-desktop-linux.rev or "";
        lastModified = inputs.codex-desktop-linux.lastModified or 1;
      };
      nixpkgs = inputs.nixpkgs;
      flake-utils = inputs.codex-desktop-linux.inputs.flake-utils;
    };
  package = flake.packages.${system}.full.overrideAttrs (old: {
    pname = "codex-desktop-full";
    name = "codex-desktop-full-${old.version}";
  });
in
{
  imports = [ inputs.codex-desktop-linux.homeManagerModules.default ];

  programs.codexDesktopLinux = {
    enable = true;
    inherit package;
  };

  home.sessionVariables.CODEX_CLI_PATH = "/etc/profiles/per-user/paul/bin/codex";
}
