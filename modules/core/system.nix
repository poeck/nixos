{ pkgs, lib, ... }:
{
  nix = {
    settings = {
      auto-optimise-store = true;
      # Enable flakes
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = [
        "https://nix-community.cachix.org"
        "https://nix-gaming.cachix.org"
        "https://hyprland.cachix.org"
        "https://cache.numtide.com"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    wget
    git
    # These 3 are reuqired for Claude sandbox
    bubblewrap
    socat
    sandbox
  ];

  time.timeZone = "Europe/Vienna";
  i18n.defaultLocale = "en_US.UTF-8";
  system.stateVersion = "24.05";

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "acli"
      "acli-unwrapped"
      "slack"
      "nvidia-x11"
      "proton-authenticator"
      "claude-desktop"
      "claude-code"
      "chatgpt-desktop-app"
      "ungoogled-chromium"
      "ungoogled-chromium-unwrapped"
      "widevine-cdm"
      "keeper-password-manager"
      "1password"
      "1password-cli"
      "onepassword-password-manager"
      "steam"
      "steam-unwrapped"
    ];
}
