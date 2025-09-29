{pkgs, ...}: let
  # Import shared user configuration
  shared = import ./settings.nix;
in {
  # ===============================================================
  #       HOME MANAGER BASICS
  # ===============================================================
  home = {
    username = shared.userName;
    homeDirectory = "/home/${shared.userName}";
    stateVersion = "24.11";
  };

  programs.home-manager.enable = true;

  # ===============================================================
  #       USER PACKAGES
  # ===============================================================
  home.packages = with pkgs; [
    # Development tools
    helix
    git
    gitui
    gh
    fzf
    fd
    ripgrep
    bat
    eza
    zoxide
    aspell
    aspellDicts.en
    aspellDicts.de

    # Terminal and shell
    ghostty
    zellij
    starship
    direnv
    nushell

    # Media applications
    vlc
    spotify
    audacity
    obs-studio
    gimp
    blender_4_4
    ffmpeg
    imagemagick
    exiftool

    # Productivity applications
    onlyoffice-desktopeditors
    zotero
    keepassxc

    # Web browsers
    google-chrome
    firefox

    # GNOME applications and tools
    pavucontrol
    gnome-tweaks
    gnome-extension-manager
    easyeffects
    helvum

    # GNOME extensions
    gnomeExtensions.forge
    gnomeExtensions.blur-my-shell
    gnomeExtensions.dash-to-dock

    # Development environments
    vscode

    # Networking tools (user-level)
    nmap
    netcat
    iperf3
    dig
    wireshark

    # Audio applications
    pulsemixer

    # Printing and scanning applications
    system-config-printer
    evince
    sane-frontends
    simple-scan

    # Utility script for GPG reset
    (writeShellScriptBin "reset-gpg-yubikey" ''
      ${gnupg}/bin/gpg-connect-agent "scd serialno" "learn --force" /bye
    '')
  ];

  # ===============================================================
  #       GIT CONFIGURATION
  # ===============================================================
  programs.git = {
    enable = true;
    userName = shared.userFullName;
    userEmail = shared.userEmail;
    signing = {
      key = shared.gpgSigningKey;
      signByDefault = true;
    };
  };

  programs.gitui = {
    enable = true;
    keyConfig = ''
      (
          move_left: Some(( code: Char('h'), modifiers: "")),
          move_right: Some(( code: Char('l'), modifiers: "")),
          move_up: Some(( code: Char('k'), modifiers: "")),
          move_down: Some(( code: Char('j'), modifiers: "")),
          stash_open: Some(( code: Char('l'), modifiers: "")),
          open_help: Some(( code: F(1), modifiers: "")),
          status_reset_item: Some(( code: Char('U'), modifiers: "SHIFT")),
      )
    '';
  };

  # ===============================================================
  #       EDITOR CONFIGURATION
  # ===============================================================
  programs.helix = {
    enable = true;
    defaultEditor = true;
    settings = {
      theme = "ayu_dark";
      editor = {
        line-number = "absolute";
        true-color = true;
        rulers = [80 120];
        color-modes = true;
        end-of-line-diagnostics = "hint";
        auto-pairs = true;
        auto-completion = true;
        auto-format = true;

        indent-guides = {
          render = true;
          character = "|";
        };

        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };

        search = {
          smart-case = true;
          wrap-around = true;
        };

        file-picker = {
          hidden = false;
          follow-symlinks = true;
          git-ignore = true;
        };
      };
    };
  };

  programs.vscode = {
    enable = true;
    profiles.default = {
      userSettings = {
        "editor.rulers" = [80 120];
        "editor.minimap.enabled" = false;
        "telemetry.telemetryLevel" = "off";
        "workbench.sideBar.location" = "right";
      };
      extensions = with pkgs.vscode-extensions; [
        ms-vscode-remote.remote-ssh
      ];
    };
  };

  # ===============================================================
  #       TERMINAL CONFIGURATION
  # ===============================================================
  programs.ghostty = {
    enable = true;
    enableBashIntegration = true;
    settings = {
      theme = "ayu";
      font-size = shared.applications.terminal.fontSize;
      maximize = true;
    };
  };

  programs.zellij = {
    enable = true;
    enableBashIntegration = true;
    settings = {
      simplified_ui = true;
      theme = "ayu_dark";
      show_startup_tips = false;
      copy_command = "${pkgs.xclip}/bin/xclip -sel clipboard";
    };
  };

  # ===============================================================
  #       SHELL CONFIGURATION
  # ===============================================================
  programs.bash = {
    enable = true;
    enableCompletion = true;
    shellAliases = {
      system-rebuild = "sudo nixos-rebuild switch --flake .#desktop";
      home-rebuild = "home-manager switch --flake .#${shared.userName}";

      # Color support
      ls = "ls --color=auto";
      grep = "grep --color=auto";
      fgrep = "fgrep --color=auto";
      egrep = "egrep --color=auto";

      # Modified commands
      df = "df -h";
      du = "du -h";
      free = "free -h";
      less = "less -i";
      mkdir = "mkdir -pv";
      ping = "ping -c 3";
      ".." = "cd ..";
    };
    bashrcExtra = ''
      export HISTSIZE=10000
      export HISTFILESIZE=20000
      export HISTCONTROL=ignoreboth:erasedups
    '';
  };

  # ===============================================================
  #       SHELL PROMPT AND TOOLS
  # ===============================================================
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    settings = {
      character = {
        success_symbol = "[>](bold green)";
        error_symbol = "[x](bold red)";
        vimcmd_symbol = "[<](bold green)";
      };
      git_status = {
        ahead = ">";
        behind = "<";
        diverged = "<>";
        renamed = "r";
        deleted = "x";
      };
      directory = {
        read_only = " ro";
      };
      git_branch = {
        symbol = "git ";
      };
      nix_shell = {
        symbol = "nix ";
      };
      os.symbols = {
        NixOS = "nix ";
      };
    };
  };

  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    nix-direnv.enable = true;
    config = {
      warn_timeout = "1h";
      load_dotenv = true;
    };
  };

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    defaultOptions = ["--height 40%" "--border"];
  };

  # ===============================================================
  #       GTK AND GNOME THEMING
  # ===============================================================
  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      gtk-theme = "Adwaita-dark";
      color-scheme = "prefer-dark";
      enable-hot-corners = false;
      gtk-print-preview-command = "${pkgs.evince}/bin/evince --preview %s";
    };

    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:maximize,minimize,close";
    };

    "org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = [
        "user-theme@gnome-shell-extensions.gcampax.github.com"
        "forge@jmmaranan.com"
        "dash-to-dock@micxgx.gmail.com"
        "blur-my-shell@aunetx"
      ];
    };
  };

  # ===============================================================
  #       XDG CONFIGURATION
  # ===============================================================
  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
    };
    mimeApps = {
      enable = true;
      defaultApplications = let
        browserDesktop =
          if shared.applications.defaultBrowser == "firefox"
          then "firefox.desktop"
          else "google-chrome.desktop";
      in {
        "text/html" = browserDesktop;
        "x-scheme-handler/http" = browserDesktop;
        "x-scheme-handler/https" = browserDesktop;
        "x-scheme-handler/about" = browserDesktop;
        "x-scheme-handler/unknown" = browserDesktop;
      };
    };
    configFile = {
      # Global gitignore
      "git/ignore".text = ''
        # Editor files
        .vscode/
        .idea/
        *.swp
        *.swo
        *~

        # OS files
        .DS_Store
        Thumbs.db

        # Development environment
        .direnv/
        .envrc.local

        # Logs and temporary files
        *.log
        *.tmp
        *.temp
      '';

      # Helix ignore patterns
      "helix/ignore".text = ''
        .git/
        node_modules/
        target/
        .direnv/
        result
        result-*
        *.tmp
        *.log
      '';
    };
  };

  # ===============================================================
  #       ENVIRONMENT VARIABLES
  # ===============================================================
  home.sessionVariables = {
    PAGER = "less";
    LESS = "-R";
  };

  # ===============================================================
  #       SYSTEMD USER SERVICES
  # ===============================================================
  systemd.user.services.set-default-volume = {
    Unit = {
      Description = "Set default audio volume";
      After = ["pipewire.service"];
      Wants = ["pipewire.service"];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ ${toString shared.applications.terminal.defaultVolume}%";
      RemainAfterExit = true;
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };
}
