{
  inputs,
  config,
  ...
}:
{
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  # ===============================================================
  #       SOPS Settings
  # ===============================================================
  # Host decryption key derived from the SSH host key. No secrets are
  # declared yet; add them under `sops.secrets` once the per-host
  # secrets.sops.yaml is created (see .sops.yaml creation_rules).
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  # ===============================================================
  #       SSH SERVER
  # ===============================================================
  host.partition.persist.extraFiles = [
    {
      file = "/etc/ssh/ssh_host_ed25519_key";
      parentDirectory.mode = "0755";
    }
    {
      file = "/etc/ssh/ssh_host_ed25519_key.pub";
      parentDirectory.mode = "0755";
    }
    {
      file = "/etc/ssh/ssh_host_rsa_key";
      parentDirectory.mode = "0755";
    }
    {
      file = "/etc/ssh/ssh_host_rsa_key.pub";
      parentDirectory.mode = "0755";
    }
  ];
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      Banner = "/etc/ssh/banner";
    };
  };
  environment.etc."ssh/banner".text = ''
    █▄ █ █ ▀▄▀ █▀█ █▀▀
    █ ▀█ █ █ █ █▄█ ▄▄█
    version ${config.system.nixos.release}
  '';
}
