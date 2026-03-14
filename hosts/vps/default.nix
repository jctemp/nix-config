{
  pkgs,
  ...
}:
{
  # ===============================================================
  #       MODULE IMPORTS
  # ===============================================================
  imports = [
    ./hardware.nix
    ./boot.nix
    ./services.nix
    ./networking.nix

    ../modules/storage.nix
    ../modules/common.nix
    ../modules/docker.nix
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
