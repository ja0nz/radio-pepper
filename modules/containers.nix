{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Helper function to decide if we need the http:// prefix
  mkAddr = addr: if lib.hasSuffix ".local" addr then "http://${addr}" else addr;

  # Port Mapping
  port = {
    whoami = "8081";
    wordpress = "8082";
  };

  # Networks
  network = {
    podman = "podman"; # The default network
    wordpress = "wordpress-net";
  };

  # Container to run
  oci = {
    whoami = {
      image = "traefik/whoami:latest";
      ports = [ "${port.whoami}:3993" ];
      environment = {
        WHOAMI_PORT_NUMBER = "3993";
      };
      networks = [ network.podman ];
    };

    wordpress = {
      image = "docker.io/library/wordpress:latest";
      ports = [ "${port.wordpress}:80" ];
      environment = {
        WORDPRESS_DB_HOST = "wordpress-db:3306";
        WORDPRESS_DB_USER = "wordpress";
        WORDPRESS_DB_PASSWORD = "wordpress";
        WORDPRESS_DB_NAME = "wordpress";
      };
      dependsOn = [ "wordpress-db" ];
      volumes = [
        "wordpress-data:/var/www/html"
      ];
      networks = [
        network.podman
        network.wordpress
      ];
    };

    wordpress-db = {
      image = "docker.io/library/mariadb:latest";
      environment = {
        MYSQL_ROOT_PASSWORD = "rootpassword";
        MYSQL_DATABASE = "wordpress";
        MYSQL_USER = "wordpress";
        MYSQL_PASSWORD = "wordpress";
      };
      volumes = [
        "wordpress-db-data:/var/lib/mysql"
      ];
      networks = [ network.wordpress ];
    };
  };
in
{
  services.caddy = {
    enable = true;
    email = "radio.pepper.cert@ja.nz";

    virtualHosts."${mkAddr "one.local"}" = {
      extraConfig = ''
        reverse_proxy localhost:${port.whoami}
        log {
          output file /var/log/caddy/whoami.log
        }
      '';
    };

    virtualHosts."${mkAddr "two.local"}" = {
      extraConfig = ''
        reverse_proxy localhost:${port.wordpress}
        log {
          output file /var/log/caddy/wordpress.log
        }
      '';
    };
  };

  # Podman
  virtualisation = {
    podman = {
      enable = true;
      autoPrune.enable = true;
    };

    oci-containers.containers = lib.mapAttrs (
      name: value:
      value
      // {
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
      }
    ) oci;
  };

  # Networks
  systemd.services.create-default-network = with config.virtualisation.oci-containers; {
    serviceConfig.Type = "oneshot";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "caddy.service" ];
    script = ''
      ${pkgs.podman}/bin/podman network exists ${network.podman} || \
      ${pkgs.podman}/bin/podman network create ${network.podman}
    '';
  };
  systemd.services.create-wordpress-network = with config.virtualisation.oci-containers; {
    serviceConfig.Type = "oneshot";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [
      "${backend}-wordpress.service"
      "${backend}-wordpress-db.service"
    ];
    script = ''
      ${pkgs.podman}/bin/podman network exists ${network.wordpress} || \
      ${pkgs.podman}/bin/podman network create --internal ${network.wordpress}
    '';
  };
}
