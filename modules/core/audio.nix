{ pkgs, ... }:
{
  services.pulseaudio.enable = false;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.extraConfig = {
      "50-bluez" = {
        "monitor.bluez.properties" = {
          "bluez5.enable-sbc-xq" = true;
          "bluez5.enable-msbc" = true;
          "bluez5.enable-hw-volume" = true;
          "bluez5.roles" = [ "a2dp_sink" "a2dp_source" "bap_sink" "bap_source" "hsp_hs" "hsp_ag" "hfp_hf" "hfp_ag" ];
        };
      };
      "51-bluez-policy" = {
        "wireplumber.settings" = {
          "bluetooth.autoswitch-to-headset-profile" = false;
        };
        "monitor.bluez.rules" = [
          {
            matches = [{ "device.name" = "~bluez_card.*"; }];
            actions = {
              update-props = {
                "bluez5.auto-connect" = [ "a2dp_sink" "a2dp_source" ];
                "bluez5.profile" = "a2dp-sink";
              };
            };
          }
        ];
      };
    };
  };

  # Allows TTS (e.g in chromium)
  services.speechd.enable = true;
  environment.systemPackages = with pkgs; [
    espeak
    espeakup
  ];
}
