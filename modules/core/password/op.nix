{
  username,
  ...
}:
{
  # 1Password CLI
  # Required for Backup and the GUI
  programs._1password.enable = true;

  # 1Password GUI
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "${username}" ];
  };

  # Zen is not in 1Password's default browser allowlist, so the extension cannot
  # reach the desktop app until the real executable basename is allowed.
  environment.etc."1password/custom_allowed_browsers" = {
    text = "zen";
    mode = "0755";
  };

  # Backup script
  environment.etc."backup-op.sh" = {
    source = ./backup.sh;
  };

  # Backup jobs
  services.cron = {
    enable = true;
    systemCronJobs = [
      "0 18 * * *   ${username}   . /etc/profile; /etc/backup-op.sh -f /home/${username}/1Password/personal.enc -a my.1password.eu -p 2c73oapof6yxfzdx75ncgnnaqa"
      "0 18 * * *   ${username}   . /etc/profile; /etc/backup-op.sh -f /home/${username}/1Password/otark.enc -a my.1password.com -p ekcl6ap4cyt4b3kzpotnmn2uwu"
    ];
  };
}
