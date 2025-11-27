{
  description = "Desktop NixOS Configuration";

  inputs = {
    # NIXOS related inputs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence.url = "github:nix-community/impermanence";
    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";

    # USER related inputs
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    blender-bin.url = "github:edolstra/nix-warez?dir=blender";
  };

  outputs =
    inputs:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations = {
        desktop = inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs;
          };
          modules = [
            {
              host.settings = {
                name = "desktop";
                stateVersion = "24.11";
                timeZone = "Europe/Berlin";
                defaultLocale = "en_US.UTF-8";
                extraLocale = "de_DE.UTF-8";
                keyboardLayout = "us";
              };

              host.users.primary = "zen";

              host.partition = {
                device = "/dev/nvme0n1";
                persist.path = "/persist";
              };
            }
            ./host/desktop/partitions.nix
            ./host/desktop/facter.nix
            ./host/desktop/testing.nix
            ./host/desktop/configuration.nix
          ];
        };
      };

      homeConfigurations = {
        zen = inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = import inputs.nixpkgs-unstable {
            inherit system;
            config.allowUnfree = true;
            overlays = [ inputs.blender-bin.overlays.default ];
          };

          extraSpecialArgs = {
            inherit inputs;
          };

          modules = [
            ./home/users/zen.nix
          ];
        };
      };

      formatter.${system} = inputs.nixpkgs.legacyPackages.${system}.nixpkgs-fmt;

      devShells.${system}.default =
        let
          pkgs = inputs.nixpkgs.legacyPackages.${system};
        in
        pkgs.mkShellNoCC {
          name = "nix-config";
          packages = with pkgs; [
            bash-language-server
            deadnix
            home-manager
            manix
            nixd
            nix-diff
            nixfmt-rfc-style
            nix-melt
            nix-tree
            statix
            taplo
          ];
        };
    };
}
