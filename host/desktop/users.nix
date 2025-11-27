{
  inputs,
  config,
  lib,
  ...
}:
{
  # ===============================================================
  #       HOME DIRECTORY SETUP
  # ===============================================================
  systemd.tmpfiles.rules = lib.foldl (
    acc: elem:
    acc
    ++ [
      "d /home/${elem} 0755 ${elem} users -"
      "d /home/${elem}/.ssh 0750 ${elem} users -"
      "d /home/${elem}/.ssh/sockets 0750 ${elem} users -"
    ]
  ) [ ] ([ config.host.users.primary ] ++ config.host.users.collection ++ config.host.users.admins);

  # ===============================================================
  #       USER DEFINITIONS
  # ===============================================================
  users.users =
    lib.genAttrs
      ([ config.host.users.primary ] ++ config.host.users.admins ++ config.host.users.collection)
      (
        name:
        let
          user = lib.throwIfNot (lib.pathExists "${inputs.self}/user/${name}") ''
            The user '${name}' is not defined.
            Please add a definition for the user under the <flake>/user/<username>.
          '' name;
          settings = import "${inputs.self}/user/${name}/settings.nix";
          checkGroups = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
        in
        {
          hashedPassword = settings.hashedPassword;
          openssh.authorizedKeys.keys = settings.authorizedKeys;
          isNormalUser = true;
          extraGroups =
            (lib.optionals (lib.any (u: u == user) ([ config.host.users.primary ] ++ config.host.users.admins))
              [
                "wheel"
              ]
            )
            ++ (checkGroups [
              "audio"
              "video"
              "docker"
              "libvirt"
              "git"
              "networkmanager"
              "scanner"
              "lp"
              "kvm"
            ]);
        }
      );
}
