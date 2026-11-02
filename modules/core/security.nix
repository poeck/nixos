{ lib, ... }:
let
  otarkRootCA = ../../certificates/otark-root-ca.crt;
in
{
  security = {
    # RealtimeKit, required for screensharing
    rtkit.enable = true;
    # Just the sudo command (?)
    sudo.enable = true;
    # Island supplies the graphical Polkit authentication agent and PAM locker.
    polkit.enable = true;
    pam.services.swaylock = { };

    # A fresh clone works without Otark's private PKI. When supplied, the public
    # root certificate is included in the normal system trust bundle.
    pki.certificateFiles = lib.optional (builtins.pathExists otarkRootCA) otarkRootCA;
  };
}
