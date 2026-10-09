{ lib, pkgs, config, ... }:

let
  mkBand = defMode: b: {
    type = b.type;
    frequency = b.frequency;
    gain = b.gain or 0.0;
    q = b.q or 0.7;
    mode = b.mode or defMode;
    slope = b.slope or "x1";
    width = 4.0;
    mute = false;
    solo = false;
  };

  mkChannel = defMode: bands:
    builtins.listToAttrs (
      lib.imap0 (i: b: lib.nameValuePair "band${toString i}" (mkBand defMode b)) bands
    );

  hpPreamp = -6.4;
  hpBands = [
    {
      type = "Lo-shelf";
      frequency = 105.0;
      gain = 7.2;
      q = 0.70;
    }
    {
      type = "Bell";
      frequency = 10000.0;
      gain = -6.2;
      q = 0.89;
    }
    {
      type = "Bell";
      frequency = 104.0;
      gain = -4.7;
      q = 0.42;
    }
    {
      type = "Bell";
      frequency = 4462.0;
      gain = 3.0;
      q = 1.72;
    }
    {
      type = "Bell";
      frequency = 550.0;
      gain = 2.1;
      q = 0.32;
    }
    {
      type = "Hi-shelf";
      frequency = 10000.0;
      gain = 1.9;
      q = 0.70;
    }
    {
      type = "Bell";
      frequency = 6261.0;
      gain = -2.4;
      q = 6.00;
    }
    {
      type = "Bell";
      frequency = 5510.0;
      gain = 1.7;
      q = 6.00;
    }
    {
      type = "Bell";
      frequency = 974.0;
      gain = -1.2;
      q = 4.63;
    }
    {
      type = "Bell";
      frequency = 718.0;
      gain = 0.7;
      q = 3.16;
    }
  ];
  hpChannel = mkChannel "APO (DR)" hpBands;

  micEqBands = [
    {
      type = "Hi-pass";
      frequency = 90.0;
      slope = "x2";
    }
    {
      type = "Bell";
      frequency = 300.0;
      gain = -2.0;
      q = 1.5;
    }
    {
      type = "Bell";
      frequency = 6000.0;
      gain = -3.0;
      q = 3.0;
    }
    {
      type = "Hi-shelf";
      frequency = 9000.0;
      gain = -2.0;
      q = 0.70;
    }
  ];
  micEqChannel = mkChannel "RLC (BT)" micEqBands;

  dockSinkNode = "alsa_output.usb-Lenovo_ThinkPad_USB-C_Dock_Audio_000000000000-00.analog-stereo";
  dockSinkDesc = "ThinkPad USB-C Dock Audio Analog Stereo";
  dockSinkRoute = "Analog Output";
in
{
  services.easyeffects = {
    enable = true;

    # Load output processing via device-specific autoload so the headphone EQ is
    # only applied to the dock output, while the input chain uses fallback autoload.
    extraPresets.dt990pro.output = {
      blocklist = [ ];
      plugins_order = [ "equalizer#0" ];
      "equalizer#0" = {
        balance = 0.0;
        bypass = false;
        "input-gain" = hpPreamp;
        "output-gain" = 0.0;
        mode = "IIR";
        "num-bands" = builtins.length hpBands;
        "pitch-left" = 0.0;
        "pitch-right" = 0.0;
        "split-channels" = false;
        left = hpChannel;
        right = hpChannel;
      };
    };

    extraPresets.flat.output = {
      blocklist = [ ];
      plugins_order = [ ];
    };

    extraPresets.auna.input = {
      blocklist = [ ];
      plugins_order = [
        "rnnoise#0"
        "gate#0"
        "equalizer#0"
        "compressor#0"
        "limiter#0"
      ];

      "rnnoise#0" = {
        bypass = false;
        "enable-vad" = false;
        "input-gain" = 0.0;
        "model-name" = "";
        "output-gain" = 0.0;
        release = 20.0;
        "use-standard-model" = true;
        "vad-thres" = 50.0;
        wet = 0.0;
      };

      "gate#0" = {
        attack = 5.0;
        bypass = false;
        "curve-threshold" = -56.0;
        "curve-zone" = -2.0;
        dry = -80.01;
        "hpf-frequency" = 10.0;
        "hpf-mode" = "Off";
        hysteresis = true;
        "hysteresis-threshold" = -3.0;
        "hysteresis-zone" = -1.0;
        "input-gain" = 0.0;
        "lpf-frequency" = 20000.0;
        "lpf-mode" = "Off";
        makeup = 0.0;
        "output-gain" = 0.0;
        reduction = -16.0;
        release = 350.0;
        "stereo-split" = false;
        wet = 0.0;
      };

      "equalizer#0" = {
        balance = 0.0;
        bypass = false;
        "input-gain" = 0.0;
        "output-gain" = 0.0;
        mode = "IIR";
        "num-bands" = builtins.length micEqBands;
        "pitch-left" = 0.0;
        "pitch-right" = 0.0;
        "split-channels" = false;
        left = micEqChannel;
        right = micEqChannel;
      };

      "compressor#0" = {
        attack = 15.0;
        "boost-amount" = 0.0;
        "boost-threshold" = -72.0;
        bypass = false;
        dry = -80.01;
        "hpf-frequency" = 10.0;
        "hpf-mode" = "Off";
        "input-gain" = 0.0;
        knee = -6.0;
        "lpf-frequency" = 20000.0;
        "lpf-mode" = "Off";
        makeup = 3.0;
        mode = "Downward";
        "output-gain" = 0.0;
        ratio = 3.0;
        release = 200.0;
        "release-threshold" = -40.0;
        "stereo-split" = false;
        threshold = -18.0;
        wet = 0.0;
      };

      "limiter#0" = {
        alr = false;
        "alr-attack" = 5.0;
        "alr-knee" = 0.0;
        "alr-release" = 50.0;
        attack = 2.0;
        bypass = false;
        dithering = "None";
        "gain-boost" = false;
        "input-gain" = 0.0;
        lookahead = 2.0;
        mode = "Herm Wide";
        "output-gain" = 0.0;
        oversampling = "None";
        release = 5.0;
        "sidechain-preamp" = 0.0;
        "sidechain-type" = "Internal";
        "stereo-link" = 100.0;
        threshold = -1.5;
      };
    };
  };

  xdg.dataFile."easyeffects/autoload/output/${dockSinkNode}:${dockSinkRoute}.json".text =
    builtins.toJSON {
      device = dockSinkNode;
      "device-description" = dockSinkDesc;
      "device-profile" = dockSinkRoute;
      "preset-name" = "dt990pro";
    };

  home.activation.easyeffectsAutoload = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    rc="${config.home.homeDirectory}/.config/easyeffects/db/easyeffectsrc"
    mkdir -p "$(dirname "$rc")"
    kw="${pkgs.kdePackages.kconfig}/bin/kwriteconfig6"
    "$kw" --file "$rc" --group Window --key outputAutoloadingUsesFallback --type bool true
    "$kw" --file "$rc" --group Window --key outputAutoloadingFallbackPreset flat
    "$kw" --file "$rc" --group Window --key inputAutoloadingUsesFallback --type bool true
    "$kw" --file "$rc" --group Window --key inputAutoloadingFallbackPreset auna
  '';
}
