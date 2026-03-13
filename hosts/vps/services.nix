_: {
  # ===============================================================
  #       FAIL2BAN
  # ===============================================================
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "24h";
    bantime-increment = {
      enable = true;
      multipliers = "1 2 4 8 16 32 64";
      maxtime = "168h"; # 1 week
      overalljails = true;
    };
    jails = {
      sshd = {
        enabled = true;
        port = "22";
        filter = "sshd";
        logpath = "/var/log/auth.log";
        maxretry = 3;
      };
    };
  };
}
