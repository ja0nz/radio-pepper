{
  pkgs,
  lib,
  mkAddr,
  ...
}:

let
  # --- CONFIG BLOCK ---
  cfg = {
    wp = {
      image = "docker.io/library/wordpress:latest";
      containerPort = "80";
      hostPort = "8082";
    };
    db = {
      image = "docker.io/library/mariadb:latest";
      port = "3306";
    };
    networks = {
      public = "podman"; # Talk to Caddy
      internal = "wordpress-net"; # Talk to DB
    };
    domain = "two.local";
  };

  # Shared container security profile
  commonOpts = {
    autoStart = true;
    extraOptions = [
      "--cap-drop=ALL"
      "--cap-add=CHOWN"
      "--cap-add=SETUID"
      "--cap-add=SETGID"
      "--cap-add=FOWNER"
      "--cap-add=DAC_OVERRIDE"
      "--cap-add=NET_BIND_SERVICE"
      "--security-opt=no-new-privileges"
    ];
  };
in
{
  services.caddy.virtualHosts."${mkAddr cfg.domain}" = {
    extraConfig = ''
      reverse_proxy localhost:${cfg.wp.hostPort}
      log { output file /var/log/caddy/wordpress.log }
    '';
  };

  virtualisation.oci-containers.containers = {
    wordpress = commonOpts // {
      image = cfg.wp.image;
      ports = [ "${cfg.wp.hostPort}:${cfg.wp.containerPort}" ];
      environment = {
        WORDPRESS_DB_HOST = "wordpress-db:${cfg.db.port}";
        WORDPRESS_DB_USER = "wordpress";
        WORDPRESS_DB_PASSWORD = "wordpress";
        WORDPRESS_DB_NAME = "wordpress";
      };
      dependsOn = [ "wordpress-db" ];
      volumes = [ "wordpress-data:/var/www/html" ];
      networks = [
        cfg.networks.public
        cfg.networks.internal
      ];
    };

    wordpress-db = commonOpts // {
      image = cfg.db.image;
      environment = {
        MYSQL_ROOT_PASSWORD = "rootpassword";
        MYSQL_DATABASE = "wordpress";
        MYSQL_USER = "wordpress";
        MYSQL_PASSWORD = "wordpress";
      };
      volumes = [ "wordpress-db-data:/var/lib/mysql" ];
      networks = [ cfg.networks.internal ];
    };
  };

  # Stack-specific internal network
  systemd.services.create-wordpress-network = {
    serviceConfig.Type = "oneshot";
    wantedBy = [
      "podman-wordpress.service"
      "podman-wordpress-db.service"
    ];
    script = ''
      ${pkgs.podman}/bin/podman network exists ${cfg.networks.internal} || \
      ${pkgs.podman}/bin/podman network create --internal ${cfg.networks.internal}
    '';
  };
}
