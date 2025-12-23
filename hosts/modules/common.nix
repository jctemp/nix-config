{ config
, pkgs
, lib
, ...
}:
let
  hostName = config.host.settings.name;
  inherit (config.host.settings) stateVersion;
  inherit (config.host.settings) timeZone;
  inherit (config.host.settings) defaultLocale;
  inherit (config.host.settings) extraLocale;
  inherit (config.host.settings) keyboardLayout;
in
{
  imports = [
    ./options.nix
    ./testing.nix
    ./users.nix
  ];

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
    inherit timeZone;
    hardwareClockInLocalTime = true;
  };

  services.timesyncd.enable = lib.mkDefault true;

  i18n = {
    inherit defaultLocale;
    extraLocaleSettings = lib.mkIf (!(isNull extraLocale)) {
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
      system-rebuild = "sudo nixos-rebuild switch --flake .#$(hostname)";
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

}
