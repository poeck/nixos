{
  username,
  ...
}:
{
  # Required for 1password-gui
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "${username}" ];
  };

  # Allow helium browser to connect
  environment.etc = {
    "1password/custom_allowed_browsers" = {
      text = ''
        helium
        chrome
        chromium
        helium-bin
        chrome-bin
        chromium-bin
      '';
      mode = "0755";

      # Equivalent to chown 0:0 (root:root)
      user = "root";
      group = "root";
    };
  };
}
