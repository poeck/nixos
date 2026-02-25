{ pkgs, ... }:
{
  programs.steam = {
    enable = true;
  };

  programs.gamemode = {
    enable = true;
    enableRenice = true; # Allows GameMode to boost process priority
    settings = {
      general = {
        renice = 10; # Sets the priority (higher = more CPU focus)
        softrealtime = "auto";
      };
      # Optional: Optimizations specifically for GPU
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 0; # Index of your NVIDIA GPU
        nv_powermizer_mode = 1; # Force "Prefer Maximum Performance"
      };
    };
  };

  environment.systemPackages = with pkgs; [
    gamescope-wsi
  ];
}
