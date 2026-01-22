{
  pkgs,
  lib,
  port,
  config,
  vars,
  ...
}:

let
  # --- CONFIG BLOCK ---
  cfg = {
    image = "docker.io/traefik/whoami:latest";
    containerPort = "3993";
    hostPort = port.whoami;
    network = "podman";
    domain = "${vars.rootDomain}";
  };
in
{
  services.caddy.virtualHosts."${cfg.domain}" = {
    extraConfig = ''
      reverse_proxy localhost:${cfg.hostPort}
    '';
  };

  virtualisation.oci-containers.containers.whoami = {
    image = cfg.image;
    ports = [ "${cfg.hostPort}:${cfg.containerPort}" ];
    environment.WHOAMI_PORT_NUMBER = cfg.containerPort;
    networks = [ cfg.network ];
    extraOptions = [
      "--cap-drop=ALL"
      "--security-opt=no-new-privileges"
    ];
  };
}
