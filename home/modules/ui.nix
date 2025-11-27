# home/modules/ui.nix
{
  pkgs,
  lib,
  ...
}:
{
  imports = [ ./cli.nix ];

  # ===============================================================
  #       WAYLAND COMPOSITOR (SWAY)
  # ===============================================================
  wayland.windowManager.sway = {
    enable = true;
    systemd = {
      enable = true;
      xdgAutostart = true;
    };
    extraOptions = [ "--unsupported-gpu" ];

    config = {
      modifier = "Mod4";
      terminal = "${pkgs.ghostty}/bin/ghostty";
      menu = "${pkgs.fuzzel}/bin/fuzzel";

      gaps = {
        inner = 5;
        outer = 5;
      };

      bars = [ ];

      startup = [
        { command = "${pkgs.networkmanagerapplet}/bin/nm-applet"; }
        { command = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"; }
        { command = "${pkgs.blueman}/bin/blueman-applet"; }
        {
          command = "systemctl --user restart waybar.service";
          always = true;
        }
        {
          command = "swaymsg workspace number 1";
          always = true;
        }
      ];

      keybindings =
        let
          mod = "Mod4";
        in
        lib.mkOptionDefault {
          "${mod}+Return" = "exec ${pkgs.ghostty}/bin/ghostty";
          "${mod}+d" = "exec ${pkgs.fuzzel}/bin/fuzzel";
          "${mod}+Shift+q" = "kill";

          # Cheatsheet
          "${mod}+Shift+slash" =
            "exec ${pkgs.ghostty}/bin/ghostty --class=floating-cheatsheet -e sh -c 'less -R ~/.config/sway/cheatsheet.txt'";

          # Vim-like focus
          "${mod}+h" = "focus left";
          "${mod}+j" = "focus down";
          "${mod}+k" = "focus up";
          "${mod}+l" = "focus right";

          # Move windows
          "${mod}+Shift+h" = "move left";
          "${mod}+Shift+j" = "move down";
          "${mod}+Shift+k" = "move up";
          "${mod}+Shift+l" = "move right";

          # Workspaces
          "${mod}+1" = "workspace number 1";
          "${mod}+2" = "workspace number 2";
          "${mod}+3" = "workspace number 3";
          "${mod}+4" = "workspace number 4";
          "${mod}+5" = "workspace number 5";
          "${mod}+6" = "workspace number 6";
          "${mod}+7" = "workspace number 7";
          "${mod}+8" = "workspace number 8";
          "${mod}+9" = "workspace number 9";

          "${mod}+Shift+1" = "move container to workspace number 1";
          "${mod}+Shift+2" = "move container to workspace number 2";
          "${mod}+Shift+3" = "move container to workspace number 3";
          "${mod}+Shift+4" = "move container to workspace number 4";
          "${mod}+Shift+5" = "move container to workspace number 5";
          "${mod}+Shift+6" = "move container to workspace number 6";
          "${mod}+Shift+7" = "move container to workspace number 7";
          "${mod}+Shift+8" = "move container to workspace number 8";
          "${mod}+Shift+9" = "move container to workspace number 9";

          # Layout
          "${mod}+f" = "fullscreen toggle";
          "${mod}+v" = "split vertical";
          "${mod}+b" = "split horizontal";
          "${mod}+s" = "layout stacking";
          "${mod}+w" = "layout tabbed";
          "${mod}+e" = "layout toggle split";
          "${mod}+Shift+space" = "floating toggle";
          "${mod}+space" = "focus mode_toggle";

          # Scratchpad
          "${mod}+Shift+minus" = "move scratchpad";
          "${mod}+minus" = "scratchpad show";

          # Screenshot
          "${mod}+p" =
            "exec ${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp)\" - | ${pkgs.wl-clipboard}/bin/wl-copy";
          "${mod}+Shift+p" =
            "exec ${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp)\" ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png";
          "${mod}+Ctrl+p" = "exec ${pkgs.grim}/bin/grim - | ${pkgs.wl-clipboard}/bin/wl-copy";
          "${mod}+Ctrl+Shift+p" =
            "exec ${pkgs.grim}/bin/grim ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png";
        };

      window.commands = [
        {
          criteria = {
            app_id = "firefox";
          };
          command = "inhibit_idle fullscreen";
        }
        {
          criteria = {
            app_id = "floating-cheatsheet";
          };
          command = "floating enable, resize set 900 700, move position center";
        }
      ];
    };
  };

  # ===============================================================
  #       WAYBAR (status bar)
  # ===============================================================
  programs.waybar = {
    enable = true;
    systemd.enable = false;
    settings = [
      {
        layer = "top";
        position = "top";
        height = 30;

        modules-left = [
          "sway/workspaces"
          "sway/mode"
        ];
        modules-center = [ ];
        modules-right = [
          "pulseaudio"
          "network"
          "bluetooth"
          "cpu"
          "memory"
          "temperature"
          "clock"
          "tray"
        ];

        "sway/workspaces" = {
          disable-scroll = true;
          all-outputs = true;
        };

        "sway/window" = {
          max-length = 50;
        };

        clock = {
          format = "{:%Y-%m-%d %H:%M}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };

        bluetooth = {
          format = " {status}";
          format-connected = " {device_alias}";
          format-connected-battery = " {device_alias} {device_battery_percentage}%";
          tooltip-format = "{controller_alias}\t{controller_address}\n\n{num_connections} connected";
          tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{num_connections} connected\n\n{device_enumerate}";
          tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
          tooltip-format-enumerate-connected-battery = "{device_alias}\t{device_address}\t{device_battery_percentage}%";
          on-click = "${pkgs.blueberry}/bin/blueberry";
        };

        cpu = {
          format = " {usage}%";
          tooltip = false;
        };

        memory = {
          format = " {}%";
        };

        temperature = {
          critical-threshold = 80;
          format = " {temperatureC}°C";
        };

        network = {
          format-wifi = " {essid} ({signalStrength}%)";
          format-ethernet = " {ifname}";
          format-disconnected = "⚠ Disconnected";
          tooltip-format = "{ifname}: {ipaddr}/{cidr}";
        };

        pulseaudio = {
          format = "{icon} {volume}%";
          format-muted = " muted";
          format-icons = {
            default = [
              ""
              ""
              ""
            ];
          };
          on-click = "${pkgs.pavucontrol}/bin/pavucontrol";
        };

        tray = {
          icon-size = 21;
          spacing = 10;
        };
      }
    ];
  };

  # ===============================================================
  #       NOTIFICATIONS
  # ===============================================================
  services.mako.enable = true;

  # ===============================================================
  #       APP LAUNCHER
  # ===============================================================
  programs.fuzzel.enable = true;

  # ===============================================================
  #       TERMINAL
  # ===============================================================
  programs.ghostty = {
    enable = true;
    enableBashIntegration = true;
    settings = {
      font-size = 12;
    };
  };

  programs.zellij = {
    enable = true;
    enableBashIntegration = true;
    settings = {
      simplified_ui = true;
      show_startup_tips = false;
      copy_command = "${pkgs.xclip}/bin/xclip -sel clipboard";
    };
  };

  # ===============================================================
  #       GTK
  # ===============================================================
  gtk.enable = true;

  # ===============================================================
  #       XDG
  # ===============================================================
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "google-chrome.desktop";
      "x-scheme-handler/http" = "google-chrome.desktop";
      "x-scheme-handler/https" = "google-chrome.desktop";
      "x-scheme-handler/about" = "google-chrome.desktop";
      "x-scheme-handler/unknown" = "google-chrome.desktop";
    };
  };

  xdg.configFile."sway/cheatsheet.txt".source = ./sway-cheatsheet.txt;

  # ===============================================================
  #       GUI APPLICATIONS
  # ===============================================================
  home.packages = with pkgs; [
    # Wayland utilities
    wl-clipboard
    grim
    slurp
    swaylock
    swayidle
    wdisplays

    # Network
    networkmanagerapplet
    polkit_gnome

    # Audio
    pavucontrol
    pulsemixer
    easyeffects
    helvum

    # Bluetooth
    bluez
    blueberry
    bluez-tools
    blueman

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

    # Printing and scanning
    system-config-printer
    evince
    sane-frontends
    simple-scan

    # Development
    vscode
    nmap
    netcat
    iperf3
    dig
    wireshark

    # Fonts
    font-awesome
    dejavu_fonts

    # Utility script for GPG reset
    (writeShellScriptBin "reset-gpg-yubikey" ''
      ${gnupg}/bin/gpg-connect-agent "scd serialno" "learn --force" /bye
    '')
  ];

  # ===============================================================
  #       VSCODE
  # ===============================================================
  programs.vscode = {
    enable = true;
    profiles.default = {
      userSettings = {
        "editor.rulers" = [
          80
          120
        ];
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
  #       SYSTEMD USER SERVICES
  # ===============================================================
  systemd.user.services.set-default-volume = {
    Unit = {
      Description = "Set default audio volume";
      After = [ "pipewire.service" ];
      Wants = [ "pipewire.service" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 30%";
      RemainAfterExit = true;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
