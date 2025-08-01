{
  config,
  pkgs,
  lib,
  ctx,
  ...
}: let
  cfg = config.module.core.audio;
in {
  options.module.core.audio = {
    defaultVolume = lib.mkOption {
      type = lib.types.int;
      default = 30;
      description = "Default audio volume (0-100)";
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.config.allowUnfree = true;

    home.packages =
      [
        pkgs.alsa-utils
        pkgs.pulsemixer
      ]
      ++ lib.optionals ctx.gui [
        pkgs.pavucontrol
        pkgs.easyeffects
        pkgs.helvum
      ]
      ++ cfg.packages
      ++ lib.optionals ctx.gui cfg.packagesWithGUI;

    systemd.user.services.set-default-volume = {
      Unit = {
        Description = "Set default audio volume";
        After = ["pipewire.service" "pulseaudio.service"];
        Wants =
          if cfg.backend == "pipewire"
          then ["pipewire.service"]
          else ["pulseaudio.service"];
      };
      Service = {
        Type = "oneshot";
        ExecStart =
          if cfg.backend == "pipewire"
          then "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ ${toString cfg.defaultVolume}%"
          else "${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ ${toString cfg.defaultVolume}%";
        RemainAfterExit = true;
      };
      Install = {
        WantedBy = ["default.target"];
      };
    };
  };
}