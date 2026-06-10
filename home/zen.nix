# home/zen.nix — add at top:
# Called as a function from flake.nix: import ./zen.nix "${inputs.self}/users/zen.nix"
# The path argument provides user identity (name, email, keys).
path:
let
  user = import path;
in
{
  imports = [
    ./modules/dev
    ./modules/desktop
    ./modules/system
  ];

  home = {
    username = user.name;
    homeDirectory = "/home/${user.name}";
    stateVersion = "24.11";
    enableNixpkgsReleaseCheck = false;
  };

  nixpkgs.config.allowUnfree = true;
  programs.home-manager.enable = true;
  programs.git = {
    settings = {
      user = {
        name = user.identity;
        inherit (user) email;
      };
    };
    signing = {
      key = "0x2A76355E27FF9075";
      signByDefault = true;
    };
  };
}
