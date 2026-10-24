{ inputs, pkgs, ... }:
let
  # Select Electron's Secret Service backend without advertising a GNOME
  # session. Wrap the binary so menu, mailto and terminal launches all agree.
  inlark = pkgs.symlinkJoin {
    name = "inlark-with-keyring";
    paths = [ (pkgs.callPackage "${inputs.inlark}/nix/package.nix" { }) ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/inlark --add-flags --password-store=gnome-libsecret
    '';
  };
in
{
  imports = [
    inputs.chatgpt-desktop-app.nixosModules.default
  ];

  environment.systemPackages = [ inlark ];

  programs = {
    chatgpt-desktop-app.enable = true;
    dconf.enable = true;
    # Default shell
    zsh.enable = true;
  };
}
