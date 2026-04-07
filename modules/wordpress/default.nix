{
  port,
  config,
  vars,
  ...
}:

let
  # Common
  publicNet = "wp-net";
  internalNet = "wp-internal-net";
  url = "${vars.DOMAIN}";

  # Server
  wp = {
    id = "wordpress-server";
    image = "docker.io/library/wordpress:latest";
    containerPort = "80";
    hostPort = port.wordpress;
  };

  # DB
  db = {
    id = "wordpress-database";
    image = "docker.io/library/mariadb:latest";
    port = "3306";
  };

  # CLI
  # cli = {
  #   id = "wordpress-cli";
  #   image = "docker.io/library/wordpress:cli-php8.5";
  # };

in
{
  # only dev
  # add dns route: cloudflared tunnel route dns $CF_TUNNEL <domain>
  myOpts.cloudflared.ingress."${url}" = "http://localhost:443";
  services.caddy.virtualHosts."${url}".extraConfig = ''
    import tinyauth_forwarder
    reverse_proxy localhost:${wp.hostPort}
  '';

  sops.secrets."wordpress_db_password" = { };
  sops.secrets."wordpress_root_password" = { };
  sops.templates."${db.id}.env" = {
    content = ''
      MYSQL_ROOT_PASSWORD=${config.sops.placeholder."wordpress_root_password"}
      MYSQL_DATABASE=wordpress
      MYSQL_USER=wordpress
      MYSQL_PASSWORD=${config.sops.placeholder."wordpress_db_password"}
    '';
  };
  sops.templates."${wp.id}.env" = {
    content = ''
      WORDPRESS_DB_NAME=wordpress
      WORDPRESS_DB_USER=wordpress
      WORDPRESS_DB_HOST=${db.id}:${db.port}
      WORDPRESS_DB_PASSWORD=${config.sops.placeholder."wordpress_db_password"}
    '';
  };

  virtualisation.quadlet.networks."${publicNet}" = { };
  virtualisation.quadlet.networks."${internalNet}" = {
    networkConfig = {
      internal = true;
    };
  };
  virtualisation.quadlet.volumes."${wp.id}" = { };
  virtualisation.quadlet.containers.${wp.id} = {
    unitConfig = {
      After = [
        "${db.id}.service"
      ];
      Requires = [
        "${db.id}.service"
      ];
    };
    containerConfig = {
      image = wp.image;
      noNewPrivileges = true;
      environmentFiles = [ config.sops.templates."${wp.id}.env".path ];
      environments.TZ = config.time.timeZone;
      publishPorts = [ "${wp.hostPort}:${wp.containerPort}" ];

      networks = [
        "${publicNet}"
        "${internalNet}"
      ];
      volumes = [
        "${wp.id}:/var/www/html"
      ];
    };
  };

  virtualisation.quadlet.volumes."${db.id}" = { };
  virtualisation.quadlet.containers.${db.id} = {
    containerConfig = {
      image = db.image;
      noNewPrivileges = true;
      environmentFiles = [ config.sops.templates."${db.id}.env".path ];
      environments.TZ = config.time.timeZone;
      networks = [
        "${internalNet}"
      ];
      volumes = [
        "${db.id}:/var/lib/mysql"
      ];
    };
  };

  # virtualisation.quadlet.containers.${cli.id} = {
  #   unitConfig = {
  #     After = [
  #       "${wp.id}.service"
  #     ];
  #     Requires = [
  #       "${wp.id}.service"
  #     ];
  #   };
  #   containerConfig = {
  #     image = cli.image;
  #     noNewPrivileges = true;
  #     environmentFiles = [ config.sops.templates."${wp.id}.env".path ];
  #     environments.TZ = config.time.timeZone;

  #     networks = [
  #       "${publicNet}"
  #       "${internalNet}"
  #     ];
  #     volumes = [
  #       "${wp.id}:/var/www/html"
  #     ];
  #   };
  # };
}
