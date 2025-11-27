{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
let
  hostName = config.host.settings.name;
  stateVersion = config.host.settings.stateVersion;
  timeZone = config.host.settings.timeZone;
  defaultLocale = config.host.settings.defaultLocale;
  extraLocale = config.host.settings.extraLocale;
  keyboardLayout = config.host.settings.keyboardLayout;
in
{
  options.host = {
    settings = {
      name = lib.mkOption {
        type = lib.types.str;
      };
      stateVersion = lib.mkOption {
        type = lib.types.str;
      };
      timeZone = lib.mkOption {
        type = lib.types.str;
      };
      defaultLocale = lib.mkOption {
        type = lib.types.str;
      };
      extraLocale = lib.mkOption {
        type = lib.types.str;
      };
      keyboardLayout = lib.mkOption {
        type = lib.types.str;
      };
    };
    users = {
      primary = lib.mkOption {
        type = lib.types.str;
      };
      collection = lib.mkOption {
        default = [ ];
        type = lib.types.listOf lib.types.str;
      };
      admins = lib.mkOption {
        default = [ ];
        type = lib.types.listOf lib.types.str;
      };
    };
  };

  config = {

    # ===============================================================
    #       SYSTEM BASICS
    # ===============================================================
    system.stateVersion = stateVersion;
    networking.hostName = hostName;
    networking.hostId = builtins.substring 0 8 (builtins.hashString "md5" hostName);

    # ===============================================================
    #       NIX CONFIGURATION
    # ===============================================================
    nix = {
      settings = {
        experimental-features = "nix-command flakes";
        auto-optimise-store = true;
        keep-outputs = true;
        trusted-users = [ "@wheel" ];
        connect-timeout = 5;
        log-lines = 25;
        min-free = 128000000;
        max-free = 1000000000;
      };
    };

    nixpkgs.config.allowUnfree = true;

    # ===============================================================
    #       LOCALE AND TIME
    # ===============================================================
    time = {
      timeZone = timeZone;
      hardwareClockInLocalTime = true;
    };

    services.timesyncd.enable = lib.mkDefault true;

    i18n = {
      defaultLocale = defaultLocale;
      extraLocaleSettings = {
        LC_ADDRESS = extraLocale;
        LC_IDENTIFICATION = extraLocale;
        LC_MEASUREMENT = extraLocale;
        LC_MONETARY = extraLocale;
        LC_NAME = extraLocale;
        LC_NUMERIC = extraLocale;
        LC_PAPER = extraLocale;
        LC_TELEPHONE = extraLocale;
        LC_TIME = extraLocale;
      };
    };

    console.keyMap = keyboardLayout;

    # ===============================================================
    #       NETWORKING
    # ===============================================================
    networking = {
      networkmanager.enable = true;
      nameservers = [
        "1.1.1.1"
        "8.8.8.8"
      ];
      firewall = {
        enable = true;
        allowedTCPPorts = [ ];
        allowedUDPPorts = [ ];
      };
      nftables.enable = true;
    };

    # TCP optimizations
    boot.kernel.sysctl = {
      "net.ipv4.tcp_fastopen" = 3;
      "net.ipv4.tcp_syncookies" = 1;
    };

    # ===============================================================
    #       Essential services
    # ===============================================================
    services.displayManager.ly = {
      enable = true;
      settings = {
        animation = "none"; # or "doom", "matrix", "none"
        hide_borders = true;
        blank_password = true;
      };
    };

    # Keep useful system services (work with Sway too)
    services.gvfs.enable = true; # Virtual filesystems
    services.udisks2.enable = true; # Disk management
    services.power-profiles-daemon.enable = true; # Power management

    # XDG portals for Wayland/Sway
    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-wlr
        xdg-desktop-portal-gtk
      ];
      config = {
        common = {
          default = [ "gtk" ];
        };
        sway = {
          default = [
            "wlr"
            "gtk"
          ];
          "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
          "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
        };
      };
    };

    # ===============================================================
    #       AUDIO (PIPEWIRE)
    # ===============================================================
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
      jack.enable = true;
    };

    # ===============================================================
    #       PRINTING AND SCANNING
    # ===============================================================
    services.printing = {
      enable = true;
      drivers = with pkgs; [
        gutenprint
        epson-escpr2
      ];
    };

    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    # ===============================================================
    #       HARDWARE SUPPORT
    # ===============================================================
    hardware = {
      enableRedistributableFirmware = true;
      graphics.enable = true;
    };
    services.fwupd.enable = true;

    # ===============================================================
    #       SECURITY
    # ===============================================================
    # TODO: rework security model
    programs.gnupg.agent = {
      enable = true;
      pinentryPackage = pkgs.pinentry-curses;
      enableSSHSupport = true;
      settings = {
        default-cache-ttl = 60;
        max-cache-ttl = 120;
        ttyname = "$GPG_TTY";
      };
    };

    programs.yubikey-touch-detector.enable = true;
    programs.ssh.startAgent = lib.mkForce false;
    services.pcscd.enable = true;
    services.udev = {
      enable = true;
      packages = [ pkgs.yubikey-personalization ];
    };

    environment = {
      shellInit = ''
        export GPG_TTY="$(tty)"
        ${pkgs.gnupg}/bin/gpg-connect-agent /bye
        export SSH_AUTH_SOCK=$(${pkgs.gnupg}/bin/gpgconf --list-dirs agent-ssh-socket)
        ${pkgs.gnupg}/bin/gpgconf --launch gpg-agent
      '';
      interactiveShellInit = ''
        export GPG_TTY="$(tty)"
        ${pkgs.gnupg}/bin/gpg-connect-agent /bye
        export SSH_AUTH_SOCK=$(${pkgs.gnupg}/bin/gpgconf --list-dirs agent-ssh-socket)
        ${pkgs.gnupg}/bin/gpgconf --launch gpg-agent
      '';
    };

    programs.fuse.userAllowOther = true;

    security.sudo = {
      extraConfig = "Defaults timestamp_timeout=15";
      wheelNeedsPassword = true;
    };

    # ===============================================================
    #       VIRTUALISATION
    # ===============================================================
    virtualisation = {
      containers.enable = true;
      oci-containers.backend = "docker";
      podman = {
        enable = true;
        dockerCompat = true;
        defaultNetwork.settings.dns_enabled = true;
      };
      spiceUSBRedirection.enable = true;
      libvirtd = {
        enable = true;
        qemu = {
          swtpm.enable = true;
          ovmf.packages = [ pkgs.OVMFFull.fd ];
        };
      };
    };

    programs.virt-manager.enable = true;

    # ===============================================================
    #       GIT SYSTEM CONFIG
    # ===============================================================
    programs.git = {
      enable = true;
      lfs.enable = true;
      prompt.enable = true;
      config = {
        color.ui = true;
        grep.lineNumber = true;
        init.defaultBranch = "main";
        core = {
          autocrlf = "input";
          editor = "${pkgs.vim}/bin/vim";
        };
        diff = {
          mnemonicprefix = true;
          rename = "copy";
        };
        url = {
          "https://github.com/" = {
            insteadOf = [
              "gh:"
              "github:"
            ];
          };
        };
      };
    };

    # ===============================================================
    #       SHELL CONFIGURATION
    # ===============================================================
    users.defaultUserShell = pkgs.bash;

    programs.bash = {
      completion.enable = true;
      shellAliases = {
        ls = "ls --color=auto";
        dir = "dir --color=auto";
        vdir = "vdir --color=auto";
        grep = "grep --color=auto";
        fgrep = "fgrep --color=auto";
        egrep = "egrep --color=auto";
        df = "df -h";
        du = "du -h";
        free = "free -h";
        less = "less -i";
        mkdir = "mkdir -pv";
        ping = "ping -c 3";
        ".." = "cd ..";
        system-rebuild = "sudo nixos-rebuild switch --flake .#desktop";
      };
    };

    # ===============================================================
    #       SYSTEM PACKAGES
    # ===============================================================
    environment.systemPackages = with pkgs; [
      # Essential system utilities
      curl
      wget
      vim
      tree
      unzip
      zip
      jq
      pciutils

      # Network diagnostics
      dnsutils
      inetutils
      mtr
      tcpdump

      # System fonts
      liberation_ttf
      corefonts
      dejavu_fonts

      # Hardware acceleration drivers
      intel-media-driver
      vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
      nvidia-vaapi-driver

      # Xorg support
      xorg.xinit
      xorg.xauth
      xterm

      # Essential security tools
      gnupg
      gpgme
      libfido2
      yubikey-personalization
      pcsctools

      # Virtualization system components
      dnsmasq
      libguestfs

      # Scanner backends
      sane-backends

      # Audio system components
      alsa-utils
    ];

    # ===============================================================
    #       DOCUMENTATION
    # ===============================================================
    documentation = {
      enable = true;
      dev.enable = true;
      doc.enable = false;
      info.enable = false;
      man.enable = true;
      nixos.enable = true;
    };

    # ===============================================================
    #       USERS
    # ===============================================================
    systemd.tmpfiles.rules = lib.foldl (
      acc: elem:
      acc
      ++ [
        "d /home/${elem}/.ssh 0750 ${elem} users -"
        "d /home/${elem}/.ssh/sockets 0750 ${elem} users -"
        "d /home/${elem} 0755 ${elem} users -" # Add this line - ensure home dir exists
      ]
    ) [ ] ([ config.host.users.primary ] ++ config.host.users.collection ++ config.host.users.admins);

    users.users =
      lib.genAttrs
        ([ config.host.users.primary ] ++ config.host.users.admins ++ config.host.users.collection)
        (
          name:
          let
            user = lib.throwIfNot (lib.pathExists "${inputs.self}/user/${name}") ''
              The user '${name}' is not defined.
              Please add a definition for the user under the <flake>/user/<username>.
            '' name;
            settings = import "${inputs.self}/user/${name}/settings.nix";
            checkGroups = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
          in
          {
            hashedPassword = settings.hashedPassword;
            openssh.authorizedKeys.keys = settings.authorizedKeys;
            isNormalUser = true;
            extraGroups =
              (lib.optionals (lib.any (u: u == user) ([ config.host.users.primary ] ++ config.host.users.admins))
                [
                  "wheel"
                ]
              )
              ++ (checkGroups [
                "audio"
                "video"
                "docker"
                "podman"
                "libvirt"
                "git"
                "networkmanager"
                "scanner"
                "lp"
                "kvm"
              ]);
          }
        );
  };
}
