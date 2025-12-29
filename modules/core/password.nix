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
}
