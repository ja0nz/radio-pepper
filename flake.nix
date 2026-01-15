{
  description = "Radio Pepper";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devenv.url = "github:cachix/devenv";
    disko = {
      url = "github:nix-community/disko";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
  };

  outputs =
    inputs@{ self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      sharedModules = [
        ./configuration.nix
        ./modules/containers.nix
      ];

      mkConfig =
        {
          extraModules ? [ ],
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            sshPort = 22;
          };
          modules = sharedModules ++ extraModules;
        };
    in
    {
      nixosConfigurations.dev-local = mkConfig {
        extraModules = [ ./local-vm.nix ];
      };

      nixosConfigurations.prod-remote = mkConfig {
        extraModules = [
          ./modules/hetzner/hardware-configuration.nix
          inputs.disko.nixosModules.disko
        ];
      };

      formatter.x86_64-linux = nixpkgs.legacyPackages.${system}.nixfmt-tree;

      # Development environment
      devShells.${system}.default = inputs.devenv.lib.mkShell {
        inherit pkgs;
        modules = [ ./devenv.nix ];
      };
    };
}
