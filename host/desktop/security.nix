{ pkgs, lib, ... }:
{
  # TODO: Rework the security model of the hosts leverging SecOPS
  # ===============================================================
  #       GPG AGENT
  # ===============================================================
  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-curses;
    enableSSHSupport = true;
    settings = {
      default-cache-ttl = 60;
      max-cache-ttl = 120;
      ttyname = "$GPG_TTY";
    };
  };

  # ===============================================================
  #       YUBIKEY SUPPORT
  # ===============================================================
  programs.yubikey-touch-detector.enable = true;
  programs.ssh.startAgent = lib.mkForce false;
  services.pcscd.enable = true;
  services.udev = {
    enable = true;
    packages = [ pkgs.yubikey-personalization ];
  };

  # ===============================================================
  #       GPG ENVIRONMENT SETUP
  # ===============================================================
  environment = {
    shellInit = ''
      export GPG_TTY="$(tty)"
      ${pkgs.gnupg}/bin/gpg-connect-agent /bye
      export SSH_AUTH_SOCK=$(${pkgs.gnupg}/bin/gpgconf --list-dirs agent-ssh-socket)
      ${pkgs.gnupg}/bin/gpgconf --launch gpg-agent
    '';
    interactiveShellInit = ''
      export GPG_TTY="$(tty)"
      ${pkgs.gnupg}/bin/gpg-connect-agent /bye
      export SSH_AUTH_SOCK=$(${pkgs.gnupg}/bin/gpgconf --list-dirs agent-ssh-socket)
      ${pkgs.gnupg}/bin/gpgconf --launch gpg-agent
    '';
  };

  # ===============================================================
  #       FUSE
  # ===============================================================
  programs.fuse.userAllowOther = true;

  # ===============================================================
  #       SUDO
  # ===============================================================
  security.sudo = {
    extraConfig = "Defaults timestamp_timeout=15";
    wheelNeedsPassword = true;
  };

  # ===============================================================
  #       LOCKING
  # ===============================================================
  security.pam.services.swaylock = {
    enable = true;
    text = ''
      auth include login
    '';
  };

  # ===============================================================
  #       SECURITY PACKAGES
  # ===============================================================
  environment.systemPackages = with pkgs; [
    swaylock-effects
    gnupg
    gpgme
    libfido2
    yubikey-personalization
    pcsctools
  ];
}
