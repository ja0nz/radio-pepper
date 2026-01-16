{
  pkgs,
  lib,
  mkAddr,
  port,
  ...
}:

let
  # --- CONFIG BLOCK ---
  cfg = {
    image = "traefik/whoami:latest";
    containerPort = "3993";
    hostPort = port.whoami;
    network = "podman";
    domain = "radiopepper.website";
  };
in
{
  services.caddy.virtualHosts."${mkAddr cfg.domain}" = {
    extraConfig = ''
      import tinyauth_forwarder
      reverse_proxy localhost:${cfg.hostPort}
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
