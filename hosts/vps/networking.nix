# hosts/vps/networking.nix
{ lib, ... }:
{
  networking = {
    useDHCP = lib.mkDefault true;
    firewall = {
      allowedTCPPorts = [ 22 ];
      allowedUDPPorts = [ ];
    };
  };

  # Explicit: use provider DNS for now.
  # TODO: replace with local dnscrypt-proxy + WireGuard listener
  # once VPN is set up, so all devices resolve through VPS.
  services.resolved.enable = true;
}
