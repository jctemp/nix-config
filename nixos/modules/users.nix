{ inputs, config, ... }:
let
  user = import "${inputs.self}/users/${config.host.users.primary}.nix";

  checkGroups = groups:
    builtins.filter (g: builtins.hasAttr g config.users.groups) groups;
in
{
  # Ensure home directory exists
  systemd.tmpfiles.rules = [
    "d /home/${user.name} 0755 ${user.name} users -"
    "d /home/${user.name}/.ssh 0750 ${user.name} users -"
    "d /home/${user.name}/.ssh/sockets 0750 ${user.name} users -"
  ];

  # Create user account
  users.users.${user.name} = {
    isNormalUser = true;
    description = user.identity;
    inherit (user) hashedPassword;
    openssh.authorizedKeys.keys = user.authorizedKeys;
    extraGroups = [
      "wheel"
      "networkmanager"
    ] ++ checkGroups [
      "audio"
      "video"
      "docker"
      "libvirtd"
      "scanner"
      "lp"
      "kvm"
    ];
  };

  # Configure root with same password and SSH keys
  users.users.root = {
    inherit (user) hashedPassword;
    openssh.authorizedKeys.keys = user.authorizedKeys;
  };
}
