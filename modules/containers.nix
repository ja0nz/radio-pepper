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
  p = {
    whoami = "8081";
  };

  # Container to run
  oci = {
    whoami = {
      image = "traefik/whoami:latest";
      ports = [ "${p.whoami}:3993" ];
      environment = {
        WHOAMI_PORT_NUMBER = "3993";
      };
    };
    # You can easily add more here later:
    # app2 = { image = "my-app:latest"; ports = [ "8082:8080" ]; };
  };
in
{
  services.caddy = {
    enable = true;
    email = "radio.pepper.cert@ja.nz";

    virtualHosts."${mkAddr "whoami.local"}" = {
      extraConfig = ''
        reverse_proxy localhost:${p.whoami}
        log {
          output file /var/log/caddy/whoami.log
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
        user = "1000:1000";
        autoStart = true;
        extraOptions = [
          "--cap-drop=ALL"
          "--security-opt=no-new-privileges"
          "--read-only" # Lets see if this is too much
        ];
      }
    ) oci;

    # oci-containers = {
    #   backend = "podman";
    #   containers.whoami = {
    #     image = "traefik/whoami:latest";
    #     ports = [ "${p.whoami}:80" ];
    #     autoStart = true;
    #   };
    # };
  };
}
