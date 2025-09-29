{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  # Import shared configuration
  shared = import ./settings.nix;

  # ===============================================================
  #       BASIC CONFIGURATION
  # ===============================================================
  hostName = shared.hostName;
  stateVersion = shared.stateVersion;
  timeZone = shared.timeZone;
  defaultLocale = shared.defaultLocale;
  extraLocale = shared.extraLocale;
  keyboardLayout = shared.keyboardLayout;

  # ===============================================================
  #       HARDWARE CONFIGURATION
  # ===============================================================
  kernelPackage = pkgs.linuxPackages;
in {
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
      trusted-users = ["@wheel"];
      connect-timeout = 5;
      log-lines = 25;
      min-free = 128000000;
      max-free = 1000000000;
    };
  };

  nixpkgs.config.allowUnfree = true;

  # ===============================================================
  #       BOOT CONFIGURATION
  # ===============================================================
  boot = {
    tmp.cleanOnBoot = true;
    kernelModules = ["tcp_bbr"];
    kernelPackages = kernelPackage;
    binfmt.emulatedSystems = ["x86_64-windows" "aarch64-linux"];
  };

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
    nameservers = ["1.1.1.1" "8.8.8.8"];
    firewall = {
      enable = true;
      allowedTCPPorts = [];
      allowedUDPPorts = [];
    };
    nftables.enable = true;
  };

  # TCP optimizations
  boot.kernel.sysctl = {
    "net.ipv4.tcp_fastopen" = 3;
    "net.ipv4.tcp_syncookies" = 1;
  };

  # ===============================================================
  #       DESKTOP ENVIRONMENT (GNOME)
  # ===============================================================
  # TODO: hyprland
  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
    displayManager.gdm = {
      enable = true;
      wayland = true;
    };
    desktopManager.gnome.enable = true;
    videoDrivers = ["nvidia"];
  };

  programs.dconf.enable = true;
  services.accounts-daemon.enable = true;
  services.gvfs.enable = true;
  services.power-profiles-daemon.enable = true;
  services.udisks2.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];
  };

  fonts.fontconfig.enable = true;

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
    openFirewall = true;
    drivers = with pkgs; [gutenprint epson-escpr2];
    webInterface = true;
    listenAddresses = ["localhost:631"];
    allowFrom = ["localhost"];
    browsing = true;
    defaultShared = false;
  };

  hardware.sane = {
    enable = true;
    extraBackends = with pkgs; [
      sane-airscan
      epkowa
    ];
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
    publish = {
      enable = true;
      userServices = true;
    };
  };

  # ===============================================================
  #       HARDWARE SUPPORT
  # ===============================================================
  hardware = {
    enableRedistributableFirmware = true;

    nvidia = {
      open = true;
      modesetting.enable = true;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };

    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        nvidia-vaapi-driver
      ];
    };

    bluetooth = {
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
  };

  services.fwupd.enable = true;

  # ===============================================================
  #       SECURITY
  # ===============================================================
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
    packages = [pkgs.yubikey-personalization];
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
        ovmf.packages = [pkgs.OVMFFull.fd];
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
}
