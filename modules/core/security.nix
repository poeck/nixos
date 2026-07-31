{ inputs, ... }:
{
  security = {
    # RealtimeKit, required for screensharing
    rtkit.enable = true;
    # Just the sudo command (?)
    sudo.enable = true;

    # Trust Otark's private PKI for internal HTTPS services.
    pki.certificateFiles = [
      "${inputs.otark-ca}/otark-root-ca.crt"
    ];
  };
}
