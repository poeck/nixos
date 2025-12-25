{ config, ... }:
{
  programs.alacritty = {
    enable = true;
    settings = {
      general.live_config_reload = true;

      scrolling = {
        history = 10000;
        multiplier = 3;
      };

      window = {
        startup_mode = "Windowed";
      };

      terminal.shell = {
        program = "tmux";
      };
    };
  };
}
