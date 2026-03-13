{
  inputs,
  config,
  pkgs,
  ...
}:
{
  # ===============================================================
  #       NIXOS-FACTER INTEGRATION
  # ===============================================================
  imports = [
    inputs.nixos-facter-modules.nixosModules.facter
  ];

  facter.reportPath = "${inputs.self}/hosts/${config.networking.hostName}/hardware.json";

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
      swaylock-effects
      libfido2
      pynitrokey-with-pcsc
    ];
}
