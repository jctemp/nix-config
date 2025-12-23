{ inputs
, config
, lib
, ...
}:
let
  cfg = config.host.partition;

  zfs = rec {
    pool = "rpool";
    root = "local/root";
    path = "${pool}/${root}";
    blank = "${path}@blank";
    rollback = ''
      zpool import -N -f ${zfs.pool}
      echo "ZFS[code=$?]: import pool ${zfs.pool}"

      zfs rollback -r ${zfs.blank}
      echo "ZFS[code=$?]: rollback of partition ${zfs.blank}"
    '';
  };

  zpoolOptions = {
    ashift = "12";
    autotrim = "on";
  };

  rootFsOptions = {
    acltype = "posixacl";
    canmount = "off";
    dnodesize = "auto";
    normalization = "formD";
    relatime = "on";
    xattr = "sa";
    compression = "zstd";
  };

  snapshotScript = ''
    set -o errexit
    set -o nounset
    set -o pipefail

    if ! zfs list -t snapshot '${zfs.blank}' > /dev/null 2>&1; then
      echo "Creating blank snapshot: ${zfs.blank}"
      zfs snapshot "${zfs.blank}"
    else
      echo "Blank snapshot already exists: ${zfs.blank}"
    fi
  '';
in
{
  # ===============================================================
  #       IMPORTS
  # ===============================================================
  imports = [
    inputs.disko.nixosModules.disko
    inputs.impermanence.nixosModules.impermanence
  ];

  # ===============================================================
  #       ZFS SERVICES
  # ===============================================================
  services.zfs = {
    autoScrub.enable = true;
    autoSnapshot.enable = false;
    trim.enable = true;
    trim.interval = "weekly";
  };

  # ===============================================================
  #       IMPERMANENCE
  # ===============================================================
  environment.persistence."${cfg.persist.path}" = {
    enable = true;
    hideMounts = true;
    directories = [
      "/etc/NetworkManager/system-connections"
      "/var/lib/bluetooth"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/var/log"
    ];
  };

  # ===============================================================
  #       BOOT CONFIGURATION
  # ===============================================================
  boot = {
    initrd.postDeviceCommands = lib.mkAfter zfs.rollback;
    tmp.cleanOnBoot = true;
    supportedFilesystems = [
      "vfat"
      "zfs"
    ];
  };

  fileSystems."${cfg.persist.path}".neededForBoot = true;

  # ===============================================================
  #       DISKO DISK CONFIGURATION
  # ===============================================================
  disko = {
    devices = {
      disk.main = {
        imageName = "nixos-disko-root-zfs";
        imageSize = "32G";
        inherit (cfg) device;
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              label = "BOOT";
              inherit (cfg.boot) size;
              type = "EF02";
            };

            esp = {
              label = "EFI";
              inherit (cfg.esp) size;
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };

            encryptedSwap = {
              inherit (cfg.swap) size;
              content = {
                type = "swap";
                randomEncryption = true;
                priority = 100;
              };
            };

            root = {
              inherit (cfg.root) size;
              content = {
                type = "zfs";
                inherit (zfs) pool;
              };
            };
          };
        };
      };

      zpool."${zfs.pool}" = {
        type = "zpool";
        mountpoint = "/";
        options = zpoolOptions;
        inherit rootFsOptions;
        datasets = {
          "local" = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };

          "${zfs.root}" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/";
            postCreateHook = snapshotScript;
          };

          "local/nix" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/nix";
          };

          "safe" = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };

          "safe/home" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/home";
          };

          "safe/persist" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = cfg.persist.path;
          };
        };
      };
    };
  };
}
