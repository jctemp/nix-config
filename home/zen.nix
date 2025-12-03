# home/users/zen.nix
_:
let
  user = import ../users/zen.nix;
in
{
  imports = [
    ./modules/wayland.nix
    ./modules/applications.nix
    ./modules/editor.nix
    ./modules/shell.nix
    ./modules/git.nix
  ];

  home = {
    username = user.name;
    homeDirectory = "/home/${user.name}";
    stateVersion = "24.11";
  };

  programs.home-manager.enable = true;
  programs.git.settings = {
    user = {
      name = user.identity;
      inherit (user) email;
    };
  };
}
