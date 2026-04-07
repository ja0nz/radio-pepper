{
  port,
  vars,
  config,
  ...
}:

let
  id = "tinyauth-auth";
  image = "ghcr.io/steveiliop56/tinyauth:v4";
  publicNet = "tinyauth-net";
  containerPort = "3000";
  hostPort = port.tinyauth;
  url = "auth.${vars.DOMAIN}";
in
{
  myOpts.cloudflared.ingress."${url}" = "http://localhost:443";
  services.caddy.virtualHosts."${url}".extraConfig = ''
    reverse_proxy localhost:${hostPort}
  '';

  virtualisation.quadlet.networks."${publicNet}" = { };
  virtualisation.quadlet.containers.${id} = {
    containerConfig = {
      inherit image;
      dropCapabilities = [ "ALL" ];
      addCapabilities = [ ];
      noNewPrivileges = true;
      environments.TZ = config.time.timeZone;
      publishPorts = [ "${hostPort}:${containerPort}" ];
      environments = {
        APP_URL = "https://${url}";
        USERS = "radiopepper:$2a$10$Ljo.eXhudwLWbAdi8lT5KuNjw/uvsVGKyDN6azrFV1DLAUw96G9p.";
      };
      networks = [ "${publicNet}" ];
    };
  };
}
