{
  description = "Radio Pepper";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    impermanence.url = "github:nix-community/impermanence";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    microvm.url = "github:microvm-nix/microvm.nix";
    microvm.inputs.nixpkgs.follows = "nixpkgs";
    quadlet-nix.url = "github:SEIAROTg/quadlet-nix";
  };

  nixConfig = {
    extra-substituters = [ "https://microvm.cachix.org" ];
    extra-trusted-public-keys = [ "microvm.cachix.org-1:oXnBc6hRE3eX5rSYdRyMYXnfzcCxC7yKPTbZXALsqys=" ];
    download-buffer-size = 536870912; # 512MB
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
        inputs.quadlet-nix.nixosModules.quadlet
      ];

      mkConfig =
        {
          extraModules ? [ ],
          extraArgs ? [ ],
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            vars = {
              sshPort = 22;
              userName = "radio";
              rootDomain = "radiopepper.website";
            };
          }
          // extraArgs;
          modules = sharedModules ++ extraModules;
        };
    in
    {
      # nix run or nix run .#dev-local
      packages.${system} = {
        default = self.packages.${system}.dev-local;
        dev-local = self.nixosConfigurations.dev-local.config.microvm.declaredRunner;
      };
      nixosConfigurations.dev-local = mkConfig {
        extraModules = [
          inputs.microvm.nixosModules.microvm
          ./modules/vm-configuration.nix
          ./modules/cloudflared.nix
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
