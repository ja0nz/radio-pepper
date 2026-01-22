{
  pkgs,
  lib,
  port,
  vars,
  ...
}:

let
  # --- CONFIG BLOCK ---
  cfg = {
    image = "ghcr.io/steveiliop56/tinyauth:v4";
    containerPort = "3000";
    hostPort = port.tinyauth;
    network = "podman";
    domain = "auth.${vars.rootDomain}";
  };
in
{
  services.caddy.virtualHosts."${cfg.domain}" = {
    extraConfig = ''
      reverse_proxy localhost:${cfg.hostPort}
    '';
  };

  virtualisation.oci-containers.containers.tinyauth = {
    image = cfg.image;
    ports = [ "${cfg.hostPort}:${cfg.containerPort}" ];

    environment = {
      APP_URL = "https://${cfg.domain}";
      USERS = "radiopepper:$2a$10$aCWwA5qW7pe/t88cfIDET..0R7EHDLpqHcROVPXOgKeyj1IFP07Km";
    };

    networks = [ cfg.network ];
    autoStart = true;
    extraOptions = [
      "--security-opt=no-new-privileges"
    ];
  };
}
