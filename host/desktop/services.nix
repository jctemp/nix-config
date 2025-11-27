{ pkgs, ... }:
{
  # ===============================================================
  #       DISPLAY MANAGER
  # ===============================================================
  services.displayManager.ly = {
    enable = true;
    settings = {
      animation = "matrix";
      hide_borders = true;
      blank_password = true;
    };
  };

  # ===============================================================
  #       XDG PORTALS
  # ===============================================================
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
      xdg-desktop-portal-gtk
    ];
    config = {
      common = {
        default = [ "gtk" ];
      };
      sway = {
        default = [
          "wlr"
          "gtk"
        ];
        "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
      };
    };
  };

  # ===============================================================
  #       SYSTEM SERVICES
  # ===============================================================
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  services.power-profiles-daemon.enable = true;
  fonts.fontconfig.enable = true;

  # ===============================================================
  #       AUDIO (PIPEWIRE)
  # ===============================================================
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
    jack.enable = true;
  };

  # ===============================================================
  #       PRINTING AND SCANNING
  # ===============================================================
  services.printing = {
    enable = true;
    drivers = with pkgs; [
      gutenprint
      epson-escpr2
    ];
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # ===============================================================
  #       SERVICE PACKAGES
  # ===============================================================
  environment.systemPackages = with pkgs; [
    # Scanner backends
    sane-backends

    # Audio utilities
    alsa-utils

    # Xorg support (for compatibility)
    xorg.xinit
    xorg.xauth
    xterm
  ];
}
