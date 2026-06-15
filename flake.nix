{
  description = "Desktop NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
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
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
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
      # Auto-discovered from ./templates: each subdirectory is a template, its
      # description read from that template's own flake.nix (single source of
      # truth). Drop in a new dir with a flake.nix and it appears here.
      templates =
        let
          dir = ./templates;
          isDir = _: type: type == "directory";
          names = builtins.attrNames (inputs.nixpkgs.lib.filterAttrs isDir (builtins.readDir dir));
          mk = name: {
            path = dir + "/${name}";
            inherit (import (dir + "/${name}/flake.nix")) description;
          };
          discovered = inputs.nixpkgs.lib.genAttrs names mk;
        in
        discovered // { default = discovered.generic; };

      nixosConfigurations = {
        workstation = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs;
          };
          modules = [
            ./nixos/hosts/workstation/default.nix

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
      };
    }
    // (inputs.flake-utils.lib.eachSystem [ "x86_64-linux" ] (
      system:
      let
        pkgs = import inputs.nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
        # Lint gate: run a tool over the flake source, succeed by touching $out.
        lintCheck =
          name: tool: cmd:
          pkgs.runCommand "check-${name}" { nativeBuildInputs = [ tool ]; } ''
            cd ${./.}
            ${cmd}
            touch $out
          '';
      in
      {
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
              description = "Format all Nix files with nixfmt (RFC style)";
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

        formatter = pkgs.nixfmt;

        # `nix flake check` gates these. Build/VM tests stay manual via
        # scripts/{test,vmtest} since a full system closure is heavy for CI.
        checks = {
          format = lintCheck "format" pkgs.nixfmt "find . -name '*.nix' -type f -exec nixfmt --check {} +";
          statix = lintCheck "statix" pkgs.statix "statix check .";
          deadnix = lintCheck "deadnix" pkgs.deadnix "deadnix --fail .";
        };

        devShells.default = pkgs.mkShellNoCC {
          name = "nix-config";
          packages = with pkgs; [
            bash-language-server
            deadnix
            home-manager
            manix
            nixd
            nix-diff
            nixfmt
            nix-melt
            nix-tree
            prettier
            statix
            taplo
            vscode-langservers-extracted
            openssl
            claude-code
          ];

          shellHook = ''
            echo "NixOS Configuration Development Environment"
            echo ""
          '';
        };
      }
    ));
}
