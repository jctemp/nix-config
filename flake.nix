{
  description = "Desktop NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";
    disko = {
      url = "github:nix-community/disko/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence.url = "github:nix-community/impermanence";
    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
    home-manager.url = "github:nix-community/home-manager/master";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    blender-bin.url = "github:edolstra/nix-warez?dir=blender";
    oisd = {
      url = "https://big.oisd.nl/domainswild";
      flake = false;
    };
  };

  outputs =
    inputs:
    {
      nixosConfigurations = {
        desktop = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs;
          };
          modules = [
            {
              host = {
                settings = {
                  name = "desktop";
                  stateVersion = "24.11";
                  timeZone = "Europe/Berlin";
                  defaultLocale = "en_US.UTF-8";
                  extraLocale = "de_DE.UTF-8";
                  keyboardLayout = "us";
                };
                users.primary = "zen";
                partition = {
                  device = "/dev/nvme0n1";
                  persist.path = "/persist";
                };
              };
            }

            ./hosts/desktop/default.nix

            (
              { lib, ... }:
              {
                virtualisation.vmVariantWithDisko = {
                  facter.reportPath = lib.mkForce null;
                  virtualisation.fileSystems."/persist".neededForBoot = true;
                };
              }
            )

            inputs.home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = false;
                useUserPackages = true;
                users.zen = import ./home/zen.nix ./users/zen.nix;
                extraSpecialArgs = { inherit inputs; };
              };
            }
          ];
        };
        vps = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs;
          };
          modules = [
            {
              host = {
                settings = {
                  name = "vps";
                  stateVersion = "25.11";
                  timeZone = "Europe/Berlin";
                  defaultLocale = "en_US.UTF-8";
                };
                users.primary = "worker";
                partition = {
                  device = "/dev/sda";
                  persist.path = "/persist";
                };
              };
            }

            ./hosts/vps/default.nix

            inputs.home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = false;
                useUserPackages = true;
                users.worker = import ./home/worker.nix ./users/worker.nix;
                extraSpecialArgs = { inherit inputs; };
              };
            }
          ];
        };
      };
    }
    // (inputs.flake-utils.lib.eachSystem [ "x86_64-linux" ] (system: {

      apps = {
        home-rebuild = {
          type = "app";
          program = "${./scripts/home-rebuild}";
          meta = {
            description = "Rebuild home-manager configuration quickly";
            mainProgram = "home-rebuild";
          };
        };
        fmt = {
          type = "app";
          program = "${./scripts/fmt}";
          meta = {
            description = "Format all Nix files with nixpkgs-fmt";
            mainProgram = "fmt";
          };
        };
        check = {
          type = "app";
          program = "${./scripts/check}";
          meta = {
            description = "Run statix and deadnix linters";
            mainProgram = "check";
          };
        };
        vmtest = {
          type = "app";
          program = "${./scripts/vmtest}";
          meta = {
            description = "Build a vm with the current host configuration";
            mainProgram = "vmtest";
          };
        };
      };

      formatter = inputs.nixpkgs.legacyPackages.${system}.nixpkgs-fmt;

      devShells.default =
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
            nixfmt
            nixfmt-tree
            nix-melt
            nix-tree
            nodePackages.prettier
            statix
            taplo
            vscode-langservers-extracted
            openssl
          ];

          shellHook = ''
            echo "NixOS Configuration Development Environment"
            echo ""
          '';
        };
    }));
}
