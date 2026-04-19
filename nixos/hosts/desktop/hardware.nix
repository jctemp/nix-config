{ inputs
, config
, pkgs
, ...
}:
{
  # ===============================================================
  #       NIXOS-FACTER INTEGRATION
  # ===============================================================
  imports = [
    inputs.nixos-facter-modules.nixosModules.facter
  ];

  facter.reportPath = "${inputs.self}/nixos/hosts/${config.networking.hostName}/hardware.json";

  # ===============================================================
  #       HARDWARE SUPPORT
  # ===============================================================
  hardware = {
    enableRedistributableFirmware = true;
    graphics.enable = true;
    nitrokey.enable = true;
  };

  services = {
    fwupd.enable = true;
    pcscd.enable = true;
  };

  # So that GnuPG can accept pinentry for Nitrokey
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = false; # don't let gpg-agent hijack SSH_AUTH_SOCK
    pinentryPackage = pkgs.pinentry-curses;
  };

  environment.systemPackages =
    let
      pynitrokey-with-pcsc = pkgs.python3Packages.pynitrokey.overridePythonAttrs (old: {
        dependencies = old.dependencies ++ old.optional-dependencies.pcsc;
      });
    in
    with pkgs;
    [
      (pkgs.writeShellScriptBin "gpg-agent-restart" ''
        gpgconf --kill gpg-agent
        gpg-agent --daemon
      '')
      ccid
      swaylock-effects
      libfido2
      pynitrokey-with-pcsc
    ];
}
