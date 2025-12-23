{ pkgs
, ...
}:
{
  imports = [
    ./hardware.nix
    ./boot.nix
    ./storage.nix
    ./services.nix
    ./security.nix

    ../modules/common.nix
    ../modules/audio.nix
    ../modules/bluetooth.nix
    ../modules/docker.nix
    ../modules/libvirtd.nix
    ../modules/networking.nix
    ../modules/nvidia.nix
    ../modules/printing.nix
    ../modules/wayland.nix
  ];

  # ===============================================================
  #       ESSENTIAL SYSTEM PACKAGES
  # ===============================================================
  environment.systemPackages = with pkgs; [
    # Core utilities
    curl
    wget
    vim
    tree
    unzip
    zip
    jq
    pciutils
    helix

    # Network diagnostics
    dnsutils
    inetutils
    mtr
    tcpdump

    # System fonts
    liberation_ttf
    corefonts
    dejavu_fonts
  ];
}
