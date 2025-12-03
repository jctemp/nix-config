{ pkgs, lib, osConfig, ... }:
let
  hasWayland = osConfig.programs.sway.enable or false;
in
{
  wayland.windowManager.sway = lib.mkIf hasWayland {
    enable = true;
    systemd = {
      enable = true;
      xdgAutostart = true;
    };
    checkConfig = false;
    extraOptions = [ "--unsupported-gpu" ];
    extraSessionCommands = ''
      export WLR_NO_HARDWARE_CURSORS=1
      export WLR_RENDERER=vulkan
    '';

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
        { command = "google-chrome"; }
        { command = "ghostty"; }
      ];

      keybindings =
        let
          mod = "Mod4";
        in
        lib.mkOptionDefault {
          "${mod}+Return" = "exec ${pkgs.ghostty}/bin/ghostty";
          "${mod}+d" = "exec ${pkgs.fuzzel}/bin/fuzzel";
          "${mod}+Shift+q" = "kill";
          "${mod}+Shift+Escape" = "exec ${pkgs.swaylock-effects}/bin/swaylock";
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
          criteria.app_id = "firefox";
          command = "inhibit_idle fullscreen";
        }
        {
          criteria.app_id = "floating-cheatsheet";
          command = "floating enable, resize set 900 700, move position center";
        }
      ];
    };
  };

  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings = [{
      layer = "top";
      position = "top";
      height = 30;

      modules-left = [ "sway/workspaces" "sway/mode" ];
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

      "sway/window".max-length = 50;

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

      memory.format = " {}%";

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
        format-icons.default = [ "" "" "" ];
        on-click = "${pkgs.pavucontrol}/bin/pavucontrol";
      };

      tray = {
        icon-size = 21;
        spacing = 10;
      };
    }];
  };

  programs.swaylock = {
    enable = true;
    package = pkgs.swaylock-effects;
    settings = {
      screenshots = true;
      effect-blur = "7x5";
      clock = true;
    };
  };

  services.mako.enable = true;

  programs.fuzzel.enable = true;

  programs.ghostty = {
    enable = true;
    enableBashIntegration = true;
    settings.font-size = 12;
  };

  xdg.configFile."sway/cheatsheet.txt".source = ./sway-cheatsheet.txt;

  home.packages = with pkgs; [
    wl-clipboard
    grim
    slurp
    swayidle
    wdisplays
  ];
}
