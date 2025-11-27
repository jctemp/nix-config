{
  inputs,
  config,
  lib,
  ...
}:
let
  hasNvidiaDevice = builtins.any (gpu: (gpu.vendor.hex or "") == "10de") (
    config.facter.report.hardware.graphics_card or [ ]
  );
  hasBluetoothDevice = builtins.length (config.facter.report.hardware.bluetooth or [ ]) > 0;
in
{
  # ===============================================================
  #       NIXOS-FACTER INTEGRATION
  # ===============================================================
  imports = [
    inputs.nixos-facter-modules.nixosModules.facter
  ];

  facter.reportPath = "${inputs.self}/host/${config.networking.hostName}/hardware.json";

  # ===============================================================
  #       HARDWARE SUPPORT
  # ===============================================================
  hardware = {
    enableRedistributableFirmware = true;
    graphics.enable = true;
  };

  services.fwupd.enable = true;

  # ===============================================================
  #       NVIDIA (detected via facter)
  # ===============================================================
  services.xserver.videoDrivers = lib.optional hasNvidiaDevice "nvidia";

  hardware.nvidia = lib.mkIf hasNvidiaDevice {
    open = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  hardware.nvidia-container-toolkit.enable = hasNvidiaDevice && config.virtualisation.docker.enable;

  # ===============================================================
  #       BLUETOOTH (detected via facter)
  # ===============================================================
  hardware.bluetooth = {
    enable = hasBluetoothDevice;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = "true";
        KernelExperimental = "true";
      };
    };
  };
}
