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
      scripts = import ./scripts { inherit pkgs; };

      sharedModules = [
        ./modules/base.nix
        ./modules/containers.nix
        inputs.sops-nix.nixosModules.sops
        inputs.quadlet-nix.nixosModules.quadlet
      ];

      mkConfig =
        {
          extraModules ? [ ],
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            vars = builtins.fromJSON (builtins.readFile ./env.json);
          };
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
      };

      formatter.x86_64-linux = pkgs.nixfmt-tree;

      devShells.${system}.default = pkgs.mkShell (
        {
          buildInputs =
            with pkgs;
            [
              hcloud
              deadnix
              age
              cloudflared
              sops
              pre-commit
              # LSP Server
              tombi
              bash-language-server
              nixd
            ]
            ++ (builtins.attrValues scripts);
          # SSH user
          shellHook = ''
            echo "commands: ${builtins.concatStringsSep ", " (builtins.attrNames scripts)}"
            export FLAKE_ROOT="$(git rev-parse --show-toplevel)"
            export SECRETS="$FLAKE_ROOT/secrets.enc.yaml"
          '';
        }
        // builtins.fromJSON (builtins.readFile ./env.json)
      );

      apps.${system} = builtins.mapAttrs (name: pkg: {
        type = "app";
        program = "${pkg}/bin/${name}";
      }) scripts;
    };
}
