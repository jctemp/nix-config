{ inputs
, config
, ...
}:
{
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  # ===============================================================
  #       SOPS Settings
  # ===============================================================
  sops = {
    defaultSopsFile = "${inputs.self}/nixos/hosts/${config.networking.hostName}/secrets.sops.yaml";
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    secrets = {
      test_key = {
        sopsFile = "${inputs.self}/secrets/common.sops.yaml";
      };
      another_secret = {
        sopsFile = "${inputs.self}/secrets/common.sops.yaml";
      };
    };
  };

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
    };
    banner = ''
      █▄ █ █ ▀▄▀ █▀█ █▀▀
      █ ▀█ █ █ █ █▄█ ▄▄█
      version ${config.system.nixos.release}
    '';
  };
}
