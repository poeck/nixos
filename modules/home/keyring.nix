{ ... }:
{
  # Start the Secret Service with the graphical session. NixOS handles PAM
  # unlocking and the D-Bus / portal registrations system-wide.
  services.gnome-keyring = {
    enable = true;
    components = [
      "secrets"
      "pkcs11"
    ];
  };
}
