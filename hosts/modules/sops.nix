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
  sops = {
    defaultSopsFile = "${inputs.self}/secrets/common/default.yaml";
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    secrets = {
      test_key = { };
      another_secret = { };
    };
  };

  # ===============================================================
  #       SSH SERVER
  # ===============================================================
  host.partition.persist.extraDirectories = [
    "/etc/ssh"
  ];
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
    banner = ''
                   ___   __             
           /#\     \QQ\ /fy;            
           \#+\     \lQvfy/             
        ,=#####=##+\ \QOy/   /,         
       /+=#######=++\ \Qq\  /+#;        
            ,——,       \O/ /+#/_        
      _____/fy/         ‘ /+###+\       
      \QOOQfy/           /##/¯¯¯¯       
       ¯¯/fy/ ,         /y#/            
        ,fy/ /+\  _____________        
         \Y  \##\ \QQqQeeOoQQQy\       
             /#|#\ ‾‾‾‾‾\EQ\‾‾‾‾       
            ,+#,\#\      \QQ\          
            \#/ \##\      \Q/          
             ‾   ‾‾‾
      ${config.networking.hostName} powered by NixOS ${config.system.nixos.release}
    '';
  };
}
