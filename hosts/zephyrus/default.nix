{ pkgs, config, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./../../modules/core
  ];

  environment.systemPackages = with pkgs; [
    # CLI for battery status
    acpi
    # CLI for dimming the screen
    brightnessctl
  ];

  powerManagement.enable = true;

  # Automatically tune
  powerManagement.powertop.enable = true;

  # Hibernate after 30m of sleep
  systemd.sleep.extraConfig = ''
    HibernateDelaySec=30m
  '';

  services = {
    power-profiles-daemon.enable = false; # Disable gnome's power profile daemon
    system76-scheduler.settings.cfsProfiles.enable = true; # Better scheduling for CPU cycles

    upower = {
      enable = true;
      # Battery thresholds
      percentageLow = 20;
      percentageCritical = 5;
      percentageAction = 3;
      # Shut down at 3% to prevent data loss
      criticalPowerAction = "PowerOff";
    };

    tlp = {
      enable = true;
      settings = {
        CPU_BOOST_ON_AC = 1;
        CPU_BOOST_ON_BAT = 1;
        CPU_HWP_DYN_BOOST_ON_AC = 1;
        CPU_HWP_DYN_BOOST_ON_BAT = 1;
        # AC and battery profiles
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
        PLATFORM_PROFILE_ON_AC = "performance";
        PLATFORM_PROFILE_ON_BAT = "balanced";
        # Start charging at 80% and stop at 90%
        START_CHARGE_THRESH_BAT1 = 80;
        STOP_CHARGE_THRESH_BAT1 = 90;
      };
    };
  };

  boot = {
    # Required by tlp (?)
    kernelModules = [ "acpi_call" ];
    extraModulePackages = with config.boot.kernelPackages; [
      # Required by tlp (?)
      acpi_call
    ];
  };

  services = {
    asusd = {
      enable = true;
      enableUserService = true;
    };
  };
}
