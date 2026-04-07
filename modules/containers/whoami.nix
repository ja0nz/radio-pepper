{
  port,
  vars,
  config,
  ...
}:

let
  id = "whoami-server";
  image = "docker.io/traefik/whoami:latest";
  publicNet = "whoami-net";
  containerPort = "3993";
  hostPort = port.whoami;
  url = "ping.${vars.DOMAIN}";
in
{
  # only dev
  # add dns route: cloudflared tunnel route dns $CF_TUNNEL dev.$url
  myOpts.cloudflared.ingress."dev-${url}" = "http://localhost:443";
  services.caddy.virtualHosts."${url}" = {
    serverAliases = [ "dev-${url}" ];
    extraConfig = ''
      reverse_proxy localhost:${hostPort}
    '';
  };

  virtualisation.quadlet.networks."${publicNet}" = { };
  virtualisation.quadlet.containers.${id} = {
    containerConfig = {
      inherit image;
      dropCapabilities = [ "ALL" ];
      addCapabilities = [ ];
      noNewPrivileges = true;
      environments.TZ = config.time.timeZone;
      publishPorts = [ "${hostPort}:${containerPort}" ];
      environments.WHOAMI_PORT_NUMBER = containerPort;
      networks = [ "${publicNet}" ];
    };
  };
}
