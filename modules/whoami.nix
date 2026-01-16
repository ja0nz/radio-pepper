{
  pkgs,
  lib,
  mkAddr,
  ...
}:

let
  # --- CONFIG BLOCK ---
  cfg = {
    image = "traefik/whoami:latest";
    containerPort = "3993";
    hostPort = "8081";
    network = "podman";
    domain = "one.local";
  };
in
{
  services.caddy.virtualHosts."${mkAddr cfg.domain}" = {
    extraConfig = ''
      reverse_proxy localhost:${cfg.hostPort}
      log { output file /var/log/caddy/whoami.log }
    '';
  };

  virtualisation.oci-containers.containers.whoami = {
    image = cfg.image;
    ports = [ "${cfg.hostPort}:${cfg.containerPort}" ];
    environment.WHOAMI_PORT_NUMBER = cfg.containerPort;
    networks = [ cfg.network ];
    autoStart = true;
    extraOptions = [
      "--cap-drop=ALL"
      "--security-opt=no-new-privileges"
    ];
  };
}
