# hosts/vps/networking.nix
{ lib, ... }:
{
  networking = {
    useDHCP = lib.mkDefault true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
      allowedUDPPorts = [ ];
    };
    nftables.enable = true;
  };
}
