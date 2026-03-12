{
  pkgs,
  lib,
  config,
  ...
}:
{
  security.pam.services.swaylock = {
    enable = true;
    text = ''
      auth include login
    '';
  };

  services.displayManager.ly = {
    enable = true;
    settings = {
      animation = "matrix";
      blank_password = true;
    };
  };

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraOptions = lib.optionals config.host.hardware.hasNvidia [
      "--unsupported-gpu"
    ];
  };

  # Nvidia-specific Wayland environment
  environment.sessionVariables = lib.mkIf config.host.hardware.hasNvidia {
    WLR_NO_HARDWARE_CURSORS = "1";
    WLR_RENDERER = "vulkan";
    NIXOS_OZONE_WL = "1";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
  };

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
      sway = lib.mkForce {
        default = [
          "wlr"
          "gtk"
        ];
        "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
      };
    };
  };

  services.gvfs.enable = true;
  services.udisks2.enable = true;
  services.power-profiles-daemon.enable = true;

  environment.systemPackages = with pkgs; [
    xorg.xinit
    xorg.xauth
    xterm
    swaylock
  ];
}
