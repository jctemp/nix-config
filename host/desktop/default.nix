{
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
  # ===============================================================
  #       MODULE IMPORTS
  # ===============================================================
  imports = [
    ./hardware.nix
    ./boot.nix
    ./storage.nix
    ./networking.nix
    ./services.nix
    ./security.nix
    ./virtualisation.nix
    ./users.nix
    ./testing.nix
  ];

  # ===============================================================
  #       HOST OPTIONS
  # ===============================================================
  options.host = {
    settings = {
      name = lib.mkOption { type = lib.types.str; };
      stateVersion = lib.mkOption { type = lib.types.str; };
      timeZone = lib.mkOption { type = lib.types.str; };
      defaultLocale = lib.mkOption { type = lib.types.str; };
      extraLocale = lib.mkOption { type = lib.types.str; };
      keyboardLayout = lib.mkOption { type = lib.types.str; };
    };
    users = {
      primary = lib.mkOption { type = lib.types.str; };
      collection = lib.mkOption {
        default = [ ];
        type = lib.types.listOf lib.types.str;
      };
      admins = lib.mkOption {
        default = [ ];
        type = lib.types.listOf lib.types.str;
      };
    };
    partition = {
      device = lib.mkOption { type = lib.types.str; };
      persist.path = lib.mkOption {
        default = "/persist";
        type = lib.types.str;
      };
      boot.size = lib.mkOption {
        default = "1M";
        type = lib.types.str;
      };
      esp.size = lib.mkOption {
        default = "2G";
        type = lib.types.str;
      };
      swap.size = lib.mkOption {
        default = "16G";
        type = lib.types.str;
      };
      root.size = lib.mkOption {
        default = "100%";
        type = lib.types.str;
      };
    };
  };

  # ===============================================================
  #       SYSTEM BASICS
  # ===============================================================
  config = {
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
      pciutils
      helix

      # Network diagnostics
      dnsutils
      inetutils
      mtr
      tcpdump

      # System fonts
      liberation_ttf
      corefonts
      dejavu_fonts
    ];
  };
}
