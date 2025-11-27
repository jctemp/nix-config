{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    inputs.nixos-facter-modules.nixosModules.facter
  ];

  options.host.facter = {
    enable = lib.mkOption {
      default = true;
      type = lib.types.bool;
    };
  };

  config =
    let
      cfg = config.host.facter;
    in
    lib.mkIf cfg.enable (
      lib.mkMerge [
        {
          facter.reportPath = "${inputs.self}/host/${config.networking.hostName}/hardware.json";
        }
        (
          let
            hasNvidiaDevice = builtins.any (gpu: (gpu.vendor.hex or "") == "10de") (
              config.facter.report.hardware.graphics_card or [ ]
            );
          in
          lib.mkIf hasNvidiaDevice {
            # ===============================================================
            #       NVIDIA
            # ===============================================================
            services.xserver.videoDrivers = [ "nvidia" ];
            # {
            hardware.nvidia = {
              open = true;
              package = config.boot.kernelPackages.nvidiaPackages.stable;
            };

            hardware.graphics = {
              extraPackages = with pkgs; [
                nvidia-vaapi-driver
              ];
            };
          }
        )
        (
          let
            hasBluetoothDevice = builtins.length (config.facter.report.hardware.bluetooth or [ ]) > 0;
          in
          lib.mkIf hasBluetoothDevice {
            # ===============================================================
            #       BLUETOOTH
            # ===============================================================
            hardware.bluetooth = {
              enable = true;
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
        )
      ]
    );
}
