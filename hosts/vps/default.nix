{ config
, pkgs
, lib
, ...
}:
let
  hostName = config.host.settings.name;
  inherit (config.host.settings) stateVersion;
  inherit (config.host.settings) timeZone;
  inherit (config.host.settings) defaultLocale;
in
{
  # ===============================================================
  #       MODULE IMPORTS
  # ===============================================================
  imports = [
    ./hardware.nix
    ./boot.nix
    ./storage.nix
    ./services.nix
    ./security.nix

    ../modules/common.nix
    ../modules/networking.nix
    ../modules/docker.nix
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
