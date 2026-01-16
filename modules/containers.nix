{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Caddy helper
  mkAddr = addr: if lib.hasSuffix ".local" addr then "http://${addr}" else addr;
  port = {
    tinyauth = "3000";
    whoami = "8081";
    wordpress = "8082";
  };
in
{
  imports = [
    ./whoami
    ./tinyauth
    # ./wordpress
  ];
  _module.args = { inherit mkAddr port; };
  sops = {
    defaultSopsFormat = "yaml";
    age.keyFile = "/var/lib/sops-nix/age-key.txt";
  };

  # --- GLOBAL SETTINGS ---
  services.caddy = {
    enable = true;
    email = "radio.pepper.cert@ja.nz";
    extraConfig = ''
      (tinyauth_forwarder) {
        forward_auth localhost:${port.tinyauth} {
          uri /api/auth/caddy
        }
      }

      # Example of how to use the snippet in VirtualHosts extraConfig:
      #   import tinyauth_forwarder
      #   reverse_proxy localhost:8080
    '';
  };

  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
  };

  # --- GLOBAL NETWORK ---
  systemd.services.create-default-network = {
    serviceConfig.Type = "oneshot";
    after = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    script = ''
      ${pkgs.podman}/bin/podman network exists podman || \
      ${pkgs.podman}/bin/podman network create podman
    '';
  };
}
