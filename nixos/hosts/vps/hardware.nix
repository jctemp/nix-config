{ inputs
, config
, pkgs
, ...
}:
{
  # ===============================================================
  #       NIXOS-FACTER INTEGRATION
  # ===============================================================
  imports = [
    inputs.nixos-facter-modules.nixosModules.facter
  ];

  facter.reportPath = "${inputs.self}/nixos/hosts/${config.networking.hostName}/hardware.json";

  # ===============================================================
  #       HARDWARE SUPPORT
  # ===============================================================
  hardware = {
    enableRedistributableFirmware = true;
  };

  # ===============================================================
  #       SYSTEM PACKAGES
  # ===============================================================
  environment.systemPackages = with pkgs; [
    pciutils
    usbutils
  ];
}
