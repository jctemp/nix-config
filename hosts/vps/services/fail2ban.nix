_: {
  services = {
    fail2ban = {
      enable = true;
      maxretry = 5;
      bantime = "24h";
      bantime-increment = {
        enable = true;
        multipliers = "1 2 4 8 16 32 64";
        maxtime = "168h";
        overalljails = true;
      };
      jails = {
        sshd = {
          enabled = true;
          settings = {
            backend = "systemd";
          };
        };
      };
    };
  };
}
