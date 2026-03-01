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

  # Backup script
  environment.etc."backup-op.sh" = {
    source = ./backup.sh;
  };

  # Backup jobs
  services.cron = {
    enable = true;
    systemCronJobs = [
      "0 18 * * *   paul   . /etc/profile; /etc/backup-op.sh -f /home/paul/1Password/personal.enc -a my.1password.eu -p 2c73oapof6yxfzdx75ncgnnaqa"
      "0 18 * * *   paul   . /etc/profile; /etc/backup-op.sh -f /home/paul/1Password/otark.enc -a my.1password.com -p ekcl6ap4cyt4b3kzpotnmn2uwu"
    ];
  };
}
