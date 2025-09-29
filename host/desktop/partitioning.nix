{
  inputs,
  config,
  lib,
  pkgs,
  ...
}: let
  # Import shared configuration
  shared = import ./settings.nix;

  # ===============================================================
  #       DISK CONFIGURATION
  # ===============================================================
  diskDevice = shared.diskDevice;
  persistPath = shared.persistPath;

  # ===============================================================
  #       ZFS POOL CONFIGURATION
  # ===============================================================
  zfsPoolName = "rpool";
  zfsRootDataset = "local/root";
  zfsRootFsPath = "${zfsPoolName}/${zfsRootDataset}";
  zfsSnapshotBlank = "${zfsRootFsPath}@blank";
  zfsRollbackCommand = ''
    zfs rollback -r ${zfsSnapshotBlank}
    echo "ZFS[code=$?]: rollback of root partition ${zfsSnapshotBlank}"
  '';

  # ===============================================================
  #       PARTITION SIZES
  # ===============================================================
  bootSize = "1M"; # BIOS boot partition
  espSize = "2G"; # EFI system partition
  swapSize = "16G"; # Encrypted swap partition
  rootSize = "100%"; # Remaining space for ZFS

  # ===============================================================
  #       ZFS OPTIONS
  # ===============================================================
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

  # ===============================================================
  #       BLANK SNAPSHOT CREATION SCRIPT
  # ===============================================================
  createBlankSnapshotScript = ''
    set -o errexit
    set -o nounset
    set -o pipefail

    if ! zfs list -t snapshot '${zfsSnapshotBlank}' > /dev/null 2>&1; then
      echo "Creating blank snapshot: ${zfsSnapshotBlank}"
      zfs snapshot "${zfsSnapshotBlank}"
    else
      echo "Blank snapshot already exists: ${zfsSnapshotBlank}"
    fi
  '';
in {
  # ===============================================================
  #       MODULE IMPORTS
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
  #       PERSISTENCE CONFIGURATION
  # ===============================================================
  environment.persistence."${persistPath}" = {
    enable = true;
    hideMounts = true;
    directories = [
      "/var/lib/systemd/coredump"
      "/var/lib/nixos"
      "/etc/NetworkManager/system-connections"
    ];
  };

  fileSystems."${persistPath}".neededForBoot = true;

  # ===============================================================
  #       BOOT CONFIGURATION
  # ===============================================================
  boot = {
    # ZFS rollback for impermanence (zfs pool not imported after device, so we
    # need to postpone the rollback and ensure mounted 'partitions')
    # -> legacy: initrd.postDeviceCommands = lib.mkAfter zfsRollbackCommand;
    initrd.postMountCommands = lib.mkAfter zfsRollbackCommand;

    # ZFS support
    supportedFilesystems = ["btrfs" "reiserfs" "vfat" "f2fs" "xfs" "ntfs" "cifs" "zfs"];

    # Boot loader configuration
    loader = {
      systemd-boot = {
        enable = shared.bootLoader == "systemd";
        configurationLimit = 5;
      };
      grub = {
        enable = shared.bootLoader == "grub";
        efiSupport = shared.bootLoader == "grub";
        configurationLimit = 5;
        zfsSupport = true;
        device =
          if shared.bootLoader == "grub"
          then diskDevice
          else "nodev";
      };
      efi.canTouchEfiVariables = true;
    };
  };

  # ===============================================================
  #       DISKO CONFIGURATION
  # ===============================================================
  disko = {
    devices = {
      # ===============================================================
      #       DISK PARTITIONING
      # ===============================================================
      disk.main = {
        imageName = "nixos-disko-root-zfs";
        device = diskDevice;
        # define VM image size - needed for disko vm test
        imageSize = "32G";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            # ===============================================================
            #       BIOS BOOT PARTITION
            # ===============================================================
            boot = {
              label = "BOOT";
              size = bootSize;
              type = "EF02"; # BIOS boot partition
            };

            # ===============================================================
            #       EFI SYSTEM PARTITION
            # ===============================================================
            esp = {
              label = "EFI";
              size = espSize;
              type = "EF00"; # EFI system partition
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = ["umask=0077"];
              };
            };

            # ===============================================================
            #       ENCRYPTED SWAP PARTITION
            # ===============================================================
            encryptedSwap = {
              size = swapSize;
              content = {
                type = "swap";
                randomEncryption = true;
                priority = 100;
              };
            };

            # ===============================================================
            #       ZFS ROOT PARTITION
            # ===============================================================
            root = {
              size = rootSize;
              content = {
                type = "zfs";
                pool = zfsPoolName;
              };
            };
          };
        };
      };

      # ===============================================================
      #       ZFS POOL CONFIGURATION
      # ===============================================================
      zpool."${zfsPoolName}" = {
        type = "zpool";
        mountpoint = "/";
        options = zpoolOptions;
        rootFsOptions = rootFsOptions;

        # ===============================================================
        #       ZFS DATASETS
        # ===============================================================
        datasets = {
          # ===============================================================
          #       LOCAL DATASETS (EPHEMERAL)
          # ===============================================================
          "local" = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };

          # Root filesystem - rolled back on boot to blank snapshot
          "${zfsRootDataset}" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/";
            postCreateHook = createBlankSnapshotScript;
          };

          # Nix store - persistent across reboots
          "local/nix" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/nix";
          };

          # ===============================================================
          #       SAFE DATASETS (PERSISTENT)
          # ===============================================================
          "safe" = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };

          # User home directories
          "safe/home" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/home";
          };

          # System persistence directory
          "safe/persist" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = persistPath;
          };
        };
      };
    };
  };

  virtualisation.vmVariantWithDisko = {
    # Ensure persistence directory is available at boot in VM
    virtualisation.fileSystems."${persistPath}".neededForBoot = true;

    # VM-specific settings
    virtualisation = {
      diskSize = 65536; # 64 GB
      memorySize = 8192; # 8GB RAM
      cores = 4; # 4 CPU cores

      # Port forwarding for services
      forwardPorts = [
        {
          from = "host";
          host.port = 8888;
          guest.port = 80;
        }
      ];
    };

    # Enable some extra packages for VM testing
    environment.systemPackages = with pkgs; [
      htop
      tree
      neofetch
    ];
  };
}
