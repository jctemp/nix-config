{
  description = "Desktop NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence.url = "github:nix-community/impermanence";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    blender-bin.url = "github:edolstra/nix-warez?dir=blender";
  };

  outputs = inputs: let
    system = "x86_64-linux";
  in {
    nixosConfigurations = {
      desktop = inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs;
        };
        modules = [
          ./host/desktop/configuration.nix
          ./host/desktop/partitioning.nix
          ./user/zen/system.nix
        ];
      };
    };

    homeConfigurations = {
      zen = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = import inputs.nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
          overlays = [inputs.blender-bin.overlays.default];
        };

        extraSpecialArgs = {
          inherit inputs;
        };

        modules = [
          ./user/zen/home.nix
        ];
      };
    };

    formatter.${system} = inputs.nixpkgs.legacyPackages.${system}.alejandra;

    devShells.${system}.default = let
      pkgs = inputs.nixpkgs.legacyPackages.${system};
    in
      pkgs.mkShellNoCC {
        name = "nix-config";
        packages = with pkgs; [
          alejandra
          deadnix
          statix
          nix-melt
          nix-diff
          nix-tree
          manix
        ];
      };
  };
}
