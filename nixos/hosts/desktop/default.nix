{
  pkgs,
  ...
}:
{
  imports = [
    ./hardware.nix
    ./boot.nix
    ./networking.nix

    ../../modules/core
    ../../modules/hardware
    ../../modules/desktop
    ../../modules/services
    ../../modules/virtualisation
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
  ];
}
