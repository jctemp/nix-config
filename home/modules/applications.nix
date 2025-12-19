{ pkgs, lib, osConfig, ... }:
let
  hasWayland = osConfig.programs.sway.enable or false;
  hasDocker = osConfig.virtualisation.docker.enable or false;
in
{
  xdg.enable = true;
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };

  gtk.enable = hasWayland;
  xdg.mimeApps = lib.mkIf hasWayland {
    enable = true;
    defaultApplications = {
      "text/html" = "google-chrome.desktop";
      "x-scheme-handler/http" = "google-chrome.desktop";
      "x-scheme-handler/https" = "google-chrome.desktop";
      "x-scheme-handler/about" = "google-chrome.desktop";
      "x-scheme-handler/unknown" = "google-chrome.desktop";

      "inode/directory" = "thunar.desktop";
      "application/x-directory" = "thunar.desktop";
    };
  };

  xdg.configFile."Thunar/uca.xml" = {
    force = true;
    text = lib.mkIf hasWayland ''
      <?xml version="1.0" encoding="UTF-8"?>
      <actions>
        <action>
          <icon>utilities-terminal</icon>
          <name>Open Terminal Here</name>
          <command>ghostty --working-directory %f</command>
          <description>Open terminal in current directory</description>
          <patterns>*</patterns>
          <startup-notify/>
          <directories/>
        </action>
        <action>
          <icon>text-editor</icon>
          <name>Edit as Root</name>
          <command>sudo helix %f</command>
          <description>Edit file with root privileges</description>
          <patterns>*</patterns>
          <text-files/>
        </action>
        <action>
          <icon>emblem-symbolic-link</icon>
          <name>Create Link</name>
          <command>ln -s %f %f.link</command>
          <description>Create symbolic link</description>
          <patterns>*</patterns>
          <other-files/>
        </action>
      </actions>
    '';
  };

  home.packages = with pkgs; [
    # CLI tools (no GUI needed)
    ffmpeg
    imagemagick
    exiftool
    nmap
    netcat
    iperf3
    dig

    # Archive formats
    zip
    unzip
    p7zip
    unrar

    # Spell checking
    aspell
    aspellDicts.en
    aspellDicts.de
  ] ++ lib.optionals hasWayland [
    # GUI applications
    networkmanagerapplet
    polkit_gnome
    pavucontrol
    pulsemixer
    easyeffects
    helvum
    bluez
    blueberry
    bluez-tools
    blueman

    xfce.thunar
    xfce.thunar-volman
    xfce.thunar-archive-plugin
    xfce.thunar-media-tags-plugin
    xfce.tumbler

    file-roller
    ffmpegthumbnailer
    poppler-utils

    vlc
    spotify
    audacity
    obs-studio
    gimp
    lmstudio
    libreoffice
    zotero
    keepassxc
    google-chrome
    system-config-printer
    evince
    sane-frontends
    simple-scan
    vscode
    wireshark
    font-awesome
    dejavu_fonts
  ] ++ lib.optionals hasDocker [
    dive
    lazydocker
  ];

  programs.vscode = lib.mkIf hasWayland {
    enable = true;
    profiles.default = {
      userSettings = {
        "editor.rulers" = [ 80 120 ];
        "editor.minimap.enabled" = false;
        "telemetry.telemetryLevel" = "off";
        "workbench.sideBar.location" = "right";
      };
      extensions = with pkgs.vscode-extensions; [
        ms-vscode-remote.remote-ssh
      ];
    };
  };

  systemd.user.services.set-default-volume = lib.mkIf hasWayland {
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
    Install.WantedBy = [ "default.target" ];
  };
}
