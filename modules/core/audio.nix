{ pkgs, ... }:
{
  services.pulseaudio.enable = false;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Allows TTS (e.g in chromium)
  services.speechd.enable = true;
  environment.systemPackages = with pkgs; [
    espeak
    espeakup
  ];
}
