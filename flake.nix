{
  description = "Radio Pepper";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    impermanence.url = "github:nix-community/impermanence";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      sharedModules = [
        ./modules/base.nix
        ./modules/containers.nix
        inputs.sops-nix.nixosModules.sops
      ];

      mkConfig =
        {
          extraModules ? [ ],
          extraArgs ? [ ],
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            sshPort = 22;
            userName = "radio";
          }
          // extraArgs;
          modules = sharedModules ++ extraModules;
        };
    in
    {
      nixosConfigurations.dev-local = mkConfig {
        extraModules = [
          ./modules/vm-configuration.nix
        ];
        extraArgs = {
          ENV = "development";
        };
      };

      nixosConfigurations.prod-remote = mkConfig {
        extraModules = [
          ./modules/vps-configuration.nix
          ./modules/hetzner/hardware-configuration.nix
          ./modules/ddclient.nix
          ./modules/hetzner/impermanence.nix
          inputs.disko.nixosModules.disko
          inputs.impermanence.nixosModules.impermanence
        ];
        extraArgs = {
          ENV = "production";
        };
      };

      formatter.x86_64-linux = nixpkgs.legacyPackages.${system}.nixfmt-tree;

      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          pkgs.mise
        ];
        shellHook = ''
          echo "Mise environment active"
        '';
      };
    };
}
