{
  port,
  vars,
  config,
  ...
}:

let
  id = "azura-server";
  image = "ghcr.io/azuracast/azuracast:latest";
  publicNet = "azura-net";
  containerPort = "80";
  hostPort = port.azurecast;
  url = "azura.${vars.DOMAIN}";
in
{
  networking.firewall.allowedTCPPorts = [
    2022 # SFTP for Music Uploads
  ]
  ++ (builtins.genList (x: x + 8000) 51); # Opens 8000-8050 for Stations/DJs

  # only dev
  # add dns route: cloudflared tunnel route dns $CF_TUNNEL dev.$url
  myOpts.cloudflared.ingress."dev-${url}" = "http://localhost:443";
  services.caddy.virtualHosts."${url}" = {
    serverAliases = [ "dev-${url}" ];
    extraConfig = ''
      import tinyauth_forwarder
      reverse_proxy localhost:${hostPort}
    '';
  };

  virtualisation.quadlet.networks."${publicNet}" = { };
  virtualisation.quadlet.containers.${id} = {
    containerConfig = {
      inherit image;
      noNewPrivileges = true;
      ulimits = [ "nofile=65536:65536" ];
      # https://www.azuracast.com/docs/getting-started/settings/
      environments = {
        TZ = config.time.timeZone;
        LANG = "en_US"; # maybe: de_DE
        APPLICATION_ENV = "production";
        COMPOSER_PLUGIN_MODE = "false"; # should only use it if you use one or more plugins with their own Composer dependencies.
        AUTO_ASSIGN_PORT_MIN = "8000";
        AUTO_ASSIGN_PORT_MAX = "8050";
        ENABLE_WEB_UPDATER = "false";
        MYSQL_RANDOM_ROOT_PASSWORD = "yes";
        MYSQL_PASSWORD = "azur4c457"; # default value, db internal only
      };
      publishPorts = [
        "${hostPort}:${containerPort}"
        "2022:2022" # SFTP
        "8000-8050:8000-8050" # Radio Streams & Inbound DJ Sources
      ];
      networks = [ "${publicNet}" ];
      volumes = [
        "azuracast_station_data:/var/azuracast/stations"
        "azuracast_backups:/var/azuracast/backups"
        "azuracast_db_data:/var/lib/mysql"
        "azuracast_uploads:/var/azuracast/storage/uploads"
        "azuracast_shoutcast:/var/azuracast/storage/shoutcast2"
        "azuracast_stereo_tool:/var/azuracast/storage/stereo_tool"
        "azuracast_geoip:/var/azuracast/storage/geoip"
        "azuracast_sftpgo:/var/azuracast/storage/sftpgo"
        # Keep your music library as a direct bind mount (read-only)
        # "/home/yourUser/media/music:/var/azuracast/myMusic/remote:ro"
        # "azuracast_metadata:/var/azuracast/myMusic"
      ];
    };
  };
}
