{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Caddy helper
  mkAddr = addr: if lib.hasSuffix ".local" addr then "http://${addr}" else addr;
in
{
  imports = [
    ./whoami
    ./wordpress
  ];
  _module.args = { inherit mkAddr; };
  sops = {
    defaultSopsFormat = "yaml";
    age.keyFile = "/var/lib/sops-nix/age-key.txt";
  };

  # --- GLOBAL SETTINGS ---
  services.caddy = {
    enable = true;
    email = "radio.pepper.cert@ja.nz";
  };

  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
  };

  # --- GLOBAL NETWORK ---
  systemd.services.create-default-network = {
    serviceConfig.Type = "oneshot";
    after = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    script = ''
      ${pkgs.podman}/bin/podman network exists podman || \
      ${pkgs.podman}/bin/podman network create podman
    '';
  };
}
