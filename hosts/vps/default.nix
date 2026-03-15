{ pkgs
, ...
}:
{
  # ===============================================================
  #       MODULE IMPORTS
  # ===============================================================
  imports = [
    ./boot.nix
    ./hardware.nix
    ./networking.nix
    ./services.nix
    ./secrets.nix

    ../modules/common.nix
    ../modules/docker.nix
    ../modules/networking.nix
    ../modules/storage.nix
  ];

  # ===============================================================
  #       SSH HARDENING
  # ===============================================================
  programs.ssh.startAgent = false;

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
    htop
    tmux

    # Network tools
    dnsutils
    inetutils
    mtr
    tcpdump

    # Development tools
    git
    rsync
  ];
}
