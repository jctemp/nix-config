{ pkgs, ... }:
{
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
  #       SMARTCARD
  # ===============================================================
  services.pcscd.enable = true;
  hardware.nitrokey.enable = true;

  # ===============================================================
  #       PACKAGES
  # ===============================================================
  environment.systemPackages = with pkgs; [
    swaylock-effects

    gnupg
    pinentry-curses
    libfido2

    nitrokey-app2
    pynitrokey

    age
    sops
  ];
}
