{...}: let
  # Import shared user configuration
  shared = import ./settings.nix;
in {
  # ===============================================================
  #       USER ACCOUNT CONFIGURATION
  # ===============================================================
  users.users.${shared.userName} = {
    hashedPassword = shared.hashedPassword;
    openssh.authorizedKeys.keys = shared.authorizedKeys;
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "audio"
      "video"
      "docker"
      "podman"
      "libvirt"
      "git"
      "networkmanager"
      "scanner"
      "lp"
      "kvm"
    ];
  };

  # ===============================================================
  #       TMPFILES RULES FOR USER
  # ===============================================================
  systemd.tmpfiles.rules = [
    "d /home/${shared.userName}/.ssh 0750 ${shared.userName} users -"
    "d /home/${shared.userName}/.ssh/sockets 0750 ${shared.userName} users -"
  ];
}
